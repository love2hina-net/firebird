/*
 *  The contents of this file are subject to the Initial
 *  Developer's Public License Version 1.0 (the "License");
 *  you may not use this file except in compliance with the
 *  License. You may obtain a copy of the License at
 *  http://www.ibphoenix.com/main.nfs?a=ibphoenix&page=ibp_idpl.
 *
 *  Software distributed under the License is distributed AS IS,
 *  WITHOUT WARRANTY OF ANY KIND, either express or implied.
 *  See the License for the specific language governing rights
 *  and limitations under the License.
 *
 *  The Original Code was created by Dmitry Yemanov
 *  for the Firebird Open Source RDBMS project.
 *
 *  Copyright (c) 2014 Dmitry Yemanov <dimitr@firebirdsql.org>
 *  and all contributors signed below.
 *
 *  All Rights Reserved.
 *  Contributor(s): ______________________________________.
 */

#include "firebird.h"
#include "../common/classes/ClumpletWriter.h"
#include "../common/isc_proto.h"
#include "../common/isc_s_proto.h"
#include "../jrd/jrd.h"

#include "Manager.h"
#include "Protocol.h"
#include "Utils.h"

using namespace Firebird;
using namespace Jrd;
using namespace Replication;

namespace Replication
{
	const size_t MAX_BG_WRITER_LAG = 10 * 1024 * 1024;	// 10 MB
}


// Table matcher

TableMatcher::TableMatcher(MemoryPool& pool,
						   const string& includeFilter,
						   const string& excludeFilter)
	: m_tables(pool)
{
	if (includeFilter.hasData())
	{
		m_includeMatcher.reset(FB_NEW_POOL(pool) SimilarToRegex(
			pool, SimilarToFlag::CASE_INSENSITIVE,
			includeFilter.c_str(), includeFilter.length(),
			"\\", 1));
	}

	if (excludeFilter.hasData())
	{
		m_excludeMatcher.reset(FB_NEW_POOL(pool) SimilarToRegex(
			pool, SimilarToFlag::CASE_INSENSITIVE,
			excludeFilter.c_str(), excludeFilter.length(),
			"\\", 1));
	}
}

bool TableMatcher::matchTable(const MetaName& tableName)
{
	try
	{
		bool enabled = false;
		if (!m_tables.get(tableName, enabled))
		{
			enabled = true;

			if (m_includeMatcher)
				enabled = m_includeMatcher->matches(tableName.c_str(), tableName.length());

			if (enabled && m_excludeMatcher)
				enabled = !m_excludeMatcher->matches(tableName.c_str(), tableName.length());

			m_tables.put(tableName, enabled);
		}

		return enabled;
	}
	catch (const Exception&)
	{
		// If we failed matching the table name due to some internal error, then
		// let's allow the table to be replicated. This is not a critical failure.
		return true;
	}
}


// Replication manager

Manager::Manager(const string& dbId,
				 const Replication::Config* config)
	: m_config(config),
	  m_replicas(getPool()),
	  m_buffers(getPool()),
	  m_queue(getPool()),
	  m_queueSize(0),
	  m_shutdown(false),
	  m_signalled(false)
{
	// Startup the journalling

	const auto tdbb = JRD_get_thread_data();
	const auto dbb = tdbb->getDatabase();

	dbb->ensureGuid(tdbb);
	const Guid& guid = dbb->dbb_guid;
	m_sequence = dbb->dbb_repl_sequence;

	if (config->journalDirectory.hasData())
	{
		m_changeLog = FB_NEW_POOL(getPool())
			ChangeLog(getPool(), dbId, guid, m_sequence, config);
	}
	else
		fb_assert(config->syncReplicas.hasData());

	// Attach to synchronous replicas (if any)

	FbLocalStatus localStatus;
	DispatcherPtr provider;

	for (const auto& iter : m_config->syncReplicas)
	{
		string database = iter;
		string login, password;

		auto pos = database.find('@');
		if (pos != string::npos)
		{
			const string temp = database.substr(0, pos);
			database = database.substr(pos + 1);

			pos = temp.find(':');
			if (pos != string::npos)
			{
				login = temp.substr(0, pos);
				password = temp.substr(pos + 1);
			}
			else
			{
				login = temp;
			}
		}

		ClumpletWriter dpb(ClumpletReader::dpbList, MAX_DPB_SIZE);
		dpb.insertByte(isc_dpb_no_db_triggers, 1);

		if (login.hasData())
		{
			dpb.insertString(isc_dpb_user_name, login);

			if (password.hasData())
				dpb.insertString(isc_dpb_password, password);
		}

		const auto attachment = provider->attachDatabase(&localStatus, database.c_str(),
												   	     dpb.getBufferLength(), dpb.getBuffer());
		if (localStatus->getState() & IStatus::STATE_ERRORS)
		{
			logPrimaryStatus(m_config->dbName, &localStatus);
			continue;
		}

		const auto replicator = attachment->createReplicator(&localStatus);
		if (localStatus->getState() & IStatus::STATE_ERRORS)
		{
			logPrimaryStatus(m_config->dbName, &localStatus);
			attachment->detach(&localStatus);
			continue;
		}

		m_replicas.add(FB_NEW_POOL(getPool()) SyncReplica(getPool(), attachment, replicator));
	}

	Thread::start(writer_thread, this, THREAD_medium, 0);
	m_startupSemaphore.enter();
}

Manager::~Manager()
{
	fb_assert(m_shutdown);
	fb_assert(m_queue.isEmpty());
	fb_assert(m_replicas.isEmpty());

	for (auto buffer : m_buffers)
		delete buffer;
}

void Manager::shutdown()
{
	if (m_shutdown)
		return;

	m_shutdown = true;

	m_workingSemaphore.release();
	m_cleanupSemaphore.enter();

	MutexLockGuard guard(m_queueMutex, FB_FUNCTION);

	// Clear the processing queue

	for (auto buffer : m_queue)
	{
		if (buffer)
			releaseBuffer(buffer);
	}

	m_queue.clear();

	// Detach from synchronous replicas

	for (auto iter : m_replicas)
	{
		iter->replicator->release();
		iter->attachment->release();
		delete iter;
	}

	m_replicas.clear();
}

UCharBuffer* Manager::getBuffer()
{
	MutexLockGuard guard(m_buffersMutex, FB_FUNCTION);

	const auto buffer = m_buffers.hasData() ?
		m_buffers.pop() : FB_NEW_POOL(getPool()) UCharBuffer(getPool());

	fb_assert(buffer->isEmpty());
	buffer->resize(sizeof(Block));
	return buffer;
}

void Manager::releaseBuffer(UCharBuffer* buffer)
{
	fb_assert(buffer);
	buffer->clear();

	MutexLockGuard guard(m_buffersMutex, FB_FUNCTION);

	if (!m_buffers.exist(buffer))
		m_buffers.add(buffer);
}

void Manager::flush(UCharBuffer* buffer, bool sync, bool prepare)
{
	fb_assert(!m_shutdown);
	fb_assert(buffer && buffer->hasData());

	const auto prepareBuffer = prepare ? buffer : nullptr;

	MutexLockGuard guard(m_queueMutex, FB_FUNCTION);

	// Add the current chunk to the queue
	m_queue.add(buffer);
	m_queueSize += buffer->getCount();

	// If the background thread is lagging too far behind,
	// replicate packets synchronously rather than relying
	// on the background thread to catch up any time soon
	const bool lagging = (m_queueSize > MAX_BG_WRITER_LAG);

	if (sync || prepare || lagging)
	{
		const auto tdbb = JRD_get_thread_data();
		const auto dbb = tdbb->getDatabase();

		for (auto& buffer : m_queue)
		{
			if (buffer)
			{
				auto length = (ULONG) buffer->getCount();
				fb_assert(length);
				bool hasData = true;

				if (m_changeLog)
				{
					if (prepareBuffer == buffer)
					{
						// Remove the opPrepareTransaction command from the journal
						fb_assert(buffer->back() == opPrepareTransaction);

						const auto block = (Block*) buffer->begin();
						block->length -= sizeof(UCHAR);
						length -= sizeof(UCHAR);
						hasData = (block->length != 0);
					}

					if (hasData)
					{
						const auto sequence = m_changeLog->write(length, buffer->begin(), sync);

						if (sequence != m_sequence)
						{
							dbb->setReplSequence(tdbb, sequence);
							m_sequence = sequence;
						}
					}

					if (prepareBuffer == buffer)
					{
						const auto block = (Block*) buffer->begin();
						block->length += sizeof(UCHAR);
						length += sizeof(UCHAR);
					}
				}

				for (auto iter : m_replicas)
				{
					if (iter->status.isSuccess())
						iter->replicator->process(&iter->status, length, buffer->begin());
				}

				m_queueSize -= length;
				releaseBuffer(buffer);
				buffer = nullptr;

				for (auto iter : m_replicas)
					iter->status.check();
			}
		}

		m_queue.clear();
		m_queueSize = 0;
	}
	else if (!m_signalled)
	{
		m_signalled = true;
		m_workingSemaphore.release();
	}
}

void Manager::bgWriter()
{
	try
	{
		// Signal about our startup

		m_startupSemaphore.release();

		// Loop to replicate queued changes

		while (!m_shutdown)
		{
			MutexLockGuard guard(m_queueMutex, FB_FUNCTION);

			for (auto& buffer : m_queue)
			{
				if (buffer)
				{
					const auto length = (ULONG) buffer->getCount();
					fb_assert(length);

					if (m_changeLog)
						m_changeLog->write(length, buffer->begin(), false);

					for (auto iter : m_replicas)
					{
						if (iter->status.isSuccess())
							iter->replicator->process(&iter->status, length, buffer->begin());
					}

					m_queueSize -= length;
					releaseBuffer(buffer);
					buffer = nullptr;
				}
			}

			guard.release();

			if (m_shutdown)
				break;

			m_signalled = false;
			m_workingSemaphore.tryEnter(1);
		}
	}
	catch (const Exception& ex)
	{
		iscLogException("Error in replicator thread", ex);
	}

	// Signal about our exit

	try
	{
		m_cleanupSemaphore.release();
	}
	catch (const Firebird::Exception& ex)
	{
		iscLogException("Error while exiting replicator thread", ex);
	}
}
