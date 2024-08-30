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
#include "../common/classes/alloc.h"
#include "../common/classes/auto.h"
#include "../common/isc_proto.h"
#include "../common/isc_s_proto.h"
#include "../common/os/os_utils.h"
#include "../common/os/path_utils.h"
#include "../jrd/jrd.h"

#include "Config.h"
#include "ChangeLog.h"
#include "Replicator.h"
#include "Utils.h"

#include <sys/types.h>
#include <sys/stat.h>

#ifdef HAVE_MMAP
#include <fcntl.h>
#include <sys/mman.h>
#endif

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#ifdef WIN_NT
#include <process.h>
#include <io.h>
#include <fcntl.h>
#endif

#ifndef O_BINARY
#define O_BINARY	0
#endif

using namespace Firebird;
using namespace Jrd;
using namespace Replication;

#if !defined(WIN_NT) && !defined(LINUX)
#pragma FB_COMPILER_MESSAGE("Add support for your platform!")
#endif

namespace
{
	const unsigned FLUSH_WAIT_INTERVAL = 1; // milliseconds

	const unsigned NO_SPACE_TIMEOUT = 10;	// seconds
	const unsigned NO_SPACE_RETRIES = 6;		// up to one minute

	const unsigned COPY_BLOCK_SIZE = 64 * 1024; // 64 KB

	const char* FILENAME_PATTERN = "%s.journal-%09" UQUADFORMAT;

	const char* FILENAME_WILDCARD = "$(filename)";
	const char* PATHNAME_WILDCARD = "$(pathname)";
	const char* ARCHPATHNAME_WILDCARD = "$(archivepathname)";

	static THREAD_ENTRY_DECLARE archiver_thread(THREAD_ENTRY_PARAM arg)
	{
		ChangeLog* const log = static_cast<ChangeLog*>(arg);
		log->bgArchiver();
		return 0;
	}

	void flushFile(int handle)
	{
#ifdef WIN_NT
		FlushFileBuffers((HANDLE) _get_osfhandle(handle));
#else
		fsync(handle);
#endif
	}

	void raiseIOError(const char* syscall, const char* filename, ISC_STATUS errcode)
	{
		Arg::Gds temp(isc_io_error);
		temp << Arg::Str(syscall);
		temp << Arg::Str(filename);
		temp << SYS_ERR(errcode);
		temp.raise();
	}
}


// ChangeLog::Segment class implementation

ChangeLog::Segment::Segment(MemoryPool& pool, const PathName& filename, int handle)
	: m_filename(pool, filename), m_handle(handle)
{
	memset(&m_builtinHeader, 0, sizeof(SegmentHeader));

	struct stat stats;
	if (fstat(m_handle, &stats) < 0 || stats.st_size < (int) sizeof(SegmentHeader))
	{
		m_header = &m_builtinHeader;
		return;
	}

	mapHeader();
}

ChangeLog::Segment::~Segment()
{
	if (m_header != &m_builtinHeader)
		unmapHeader();

	if (m_handle != -1)
		::close(m_handle);
}

void ChangeLog::Segment::init(FB_UINT64 sequence, const Guid& guid)
{
	fb_assert(sizeof(CHANGELOG_SIGNATURE) == sizeof(m_header->hdr_signature));
	strcpy(m_header->hdr_signature, CHANGELOG_SIGNATURE);
	m_header->hdr_version = CHANGELOG_CURRENT_VERSION;
	m_header->hdr_state = SEGMENT_STATE_USED;
	memcpy(&m_header->hdr_guid, &guid, sizeof(Guid));
	m_header->hdr_sequence = sequence;
	m_header->hdr_length = sizeof(SegmentHeader);

	flush(false);
}

bool ChangeLog::Segment::validate(const Guid& guid) const
{
	if (strcmp(m_header->hdr_signature, CHANGELOG_SIGNATURE))
		return false;

	if (m_header->hdr_version != CHANGELOG_CURRENT_VERSION)
		return false;

	if (m_header->hdr_state != SEGMENT_STATE_FREE &&
		m_header->hdr_state != SEGMENT_STATE_USED &&
		m_header->hdr_state != SEGMENT_STATE_FULL &&
		m_header->hdr_state != SEGMENT_STATE_ARCH)
	{
		return false;
	}

	if (memcmp(&m_header->hdr_guid, &guid, sizeof(Guid)))
		return false;

	return true;
}

void ChangeLog::Segment::copyTo(const PathName& filename) const
{
	fb_assert(m_header != &m_builtinHeader);

	if (os_utils::lseek(m_handle, 0, SEEK_SET) != 0)
		raiseIOError("seek", m_filename.c_str(), ERRNO);

	const auto totalLength = m_header->hdr_length;
	fb_assert(totalLength > sizeof(SegmentHeader));

	const auto dstHandle = os_utils::openCreateSharedFile(filename.c_str(), O_TRUNC | O_BINARY);

	AutoFile dstFile(dstHandle);

	Vector<UCHAR, COPY_BLOCK_SIZE> buffer;
	const auto data = buffer.begin();

	for (FB_UINT64 offset = 0; offset < totalLength; offset += COPY_BLOCK_SIZE)
	{
		const auto remaining = totalLength - offset;
		const SINT64 length = MIN(remaining, COPY_BLOCK_SIZE);

		if (::read(m_handle, data, length) != length)
		{
			const ISC_STATUS errcode = ERRNO;

			dstFile.release();
			unlink(filename.c_str());
			raiseIOError("read", m_filename.c_str(), errcode);
		}

		if (::write(dstFile, data, length) != length)
		{
			const ISC_STATUS errcode = ERRNO;

			dstFile.release();
			unlink(filename.c_str());
			raiseIOError("write", filename.c_str(), errcode);
		}
	}

	flushFile(dstHandle);
}

void ChangeLog::Segment::append(ULONG length, const UCHAR* data)
{
	fb_assert(m_header != &m_builtinHeader);
	fb_assert(m_header->hdr_state == SEGMENT_STATE_USED);
	fb_assert(length);

	const auto currentLength = (SINT64) m_header->hdr_length;

	if (os_utils::lseek(m_handle, currentLength, SEEK_SET) != currentLength)
		raiseError("Journal file %s seek failed (error %d)", m_filename.c_str(), ERRNO);

	if (::write(m_handle, data, length) != length)
		raiseError("Journal file %s write failed (error %d)", m_filename.c_str(), ERRNO);

	m_header->hdr_length += length;
}

void ChangeLog::Segment::setState(SegmentState state)
{
	const auto full = (state == SEGMENT_STATE_FULL);
	m_header->hdr_state = state;
	flush(full);

	if ((state == SEGMENT_STATE_FREE) && (m_header != &m_builtinHeader))
		closeFile();
}

void ChangeLog::Segment::closeFile()
{
	if (m_header == &m_builtinHeader)
	{
		fb_assert(m_handle == -1);
		return;
	}

	memcpy(&m_builtinHeader, m_header, sizeof(SegmentHeader));

	unmapHeader();

	if (m_handle != -1)
	{
		::close(m_handle);
		m_handle = -1;
	}

	m_header = &m_builtinHeader;
}

void ChangeLog::Segment::truncate()
{
	fb_assert(m_header != &m_builtinHeader);

	const auto length = m_header->hdr_length;

	unmapHeader();

#ifdef WIN_NT
	LARGE_INTEGER newSize;
	newSize.QuadPart = (ULONGLONG) length;

	const auto hndl = (HANDLE) _get_osfhandle(m_handle);
	const auto ret = SetFilePointer(hndl, newSize.LowPart, &newSize.HighPart, FILE_BEGIN);
	if (ret == INVALID_SET_FILE_POINTER || !SetEndOfFile(hndl))
#else
	if (os_utils::ftruncate(m_handle, length))
#endif
		raiseError("Journal file %s truncate failed (error %d)", m_filename.c_str(), ERRNO);

	mapHeader();
}

void ChangeLog::Segment::flush(bool data)
{
	if (data)
		flushFile(m_handle);

#ifdef WIN_NT
	FlushViewOfFile(m_header, 0);
#else
	msync(m_header, sizeof(SegmentHeader), MS_SYNC);
#endif
}

void ChangeLog::Segment::mapHeader()
{
#ifdef WIN_NT
	m_mapping = CreateFileMapping((HANDLE) _get_osfhandle(m_handle), NULL, PAGE_READWRITE,
								  0, sizeof(SegmentHeader), NULL);

	if (m_mapping == INVALID_HANDLE_VALUE)
		raiseError("Journal file %s mapping failed (error %d)", m_filename.c_str(), ERRNO);

	auto address = MapViewOfFile(m_mapping, FILE_MAP_READ | FILE_MAP_WRITE,
								  0, 0, sizeof(SegmentHeader));

	if (!address)
		raiseError("Journal file %s mapping failed (error %d)", m_filename.c_str(), ERRNO);
#else
	auto address = mmap(NULL, sizeof(SegmentHeader), PROT_READ | PROT_WRITE, MAP_SHARED, m_handle, 0);

	if (address == MAP_FAILED)
		raiseError("Journal file %s mapping failed (error %d)", m_filename.c_str(), ERRNO);
#endif

	m_header = (SegmentHeader*) address;
}

void ChangeLog::Segment::unmapHeader()
{
#ifdef WIN_NT
	UnmapViewOfFile(m_header);
	CloseHandle(m_mapping);
	m_mapping = INVALID_HANDLE_VALUE;
#else
	munmap(m_header, sizeof(SegmentHeader));
#endif

	m_header = NULL;
}

PathName ChangeLog::Segment::getFileName() const
{
	PathName directory, filename;
	PathUtils::splitLastComponent(directory, filename, m_filename);

	return filename;
}


// ChangeLog class implementation

ChangeLog::ChangeLog(MemoryPool& pool,
					 const string& dbId,
					 const Guid& guid,
					 const FB_UINT64 sequence,
					 const Replication::Config* config)
	: PermanentStorage(pool),
	  m_dbId(dbId), m_config(config), m_segments(pool),
	  m_sequence(sequence), m_generation(0), m_shutdown(false)
{
	memcpy(&m_guid, &guid, sizeof(Guid));

	initSharedFile();

	{ // scope
		LockGuard guard(this);

		// If the server crashes while archiving, segments may remain in the ARCH state forever.
		// This code allows to recover their state and retry archiving them.

		const auto state = m_sharedMemory->getHeader();

		if (!state->pidUpper)
		{
			fb_assert(!state->pidLower);

			for (const auto segment : m_segments)
			{
				if (segment->getState() == SEGMENT_STATE_ARCH)
					segment->setState(SEGMENT_STATE_FULL);
			}
		}

		linkSelf();
	}

	Thread::start(archiver_thread, this, THREAD_medium, 0);
	m_startupSemaphore.enter();
	m_workingSemaphore.release();
}

ChangeLog::~ChangeLog()
{
	m_shutdown = true;

	m_workingSemaphore.release();
	m_cleanupSemaphore.enter();

	try
	{
		LockGuard guard(this);

		if (unlinkSelf())
		{
			// We're the last owner going away, so mark the active segment as full.
			// Then attempt archiving the full segments.

			switchActiveSegment();

			// At this point checkouts are disabled, thus it's safe
			// to iterate through the segments without restarts

			for (const auto segment : m_segments)
			{
				if (segment->getState() == SEGMENT_STATE_FULL)
					archiveSegment(segment);
			}

			m_sharedMemory->removeMapFile();
		}
	}
	catch (const Exception&)
	{}	// no-op

	clearSegments();
}

void ChangeLog::initSharedFile()
{
	PathName filename;
	filename.printf(REPL_FILE, m_dbId.c_str());

	m_sharedMemory.reset(FB_NEW_POOL(getPool())
		SharedMemory<State>(filename.c_str(), STATE_MAPPING_SIZE, this));

	fb_assert(m_sharedMemory->getHeader()->mhb_type == SharedMemoryBase::SRAM_CHANGELOG_STATE);
	fb_assert(m_sharedMemory->getHeader()->mhb_header_version == MemoryHeader::HEADER_VERSION);
	fb_assert(m_sharedMemory->getHeader()->mhb_version == STATE_VERSION);
}

void ChangeLog::lockState()
{
	m_localMutex.enter(FB_FUNCTION);
	m_sharedMemory->mutexLock();

	// Reattach if someone has just deleted the shared file

	while (m_sharedMemory->getHeader()->isDeleted())
	{
		// Shared memory must be empty at this point
		fb_assert(!m_sharedMemory->getHeader()->pidLower);
		fb_assert(!m_sharedMemory->getHeader()->pidUpper);

		m_sharedMemory->mutexUnlock();
		m_sharedMemory.reset();

		Thread::yield();

		initSharedFile();
		m_sharedMemory->mutexLock();
	}

	try
	{
		const auto state = m_sharedMemory->getHeader();

		if (m_segments.isEmpty() || state->generation != m_generation)
			initSegments();
	}
	catch (const Exception&)
	{
		unlockState();
		throw;
	}
}

void ChangeLog::unlockState()
{
	m_sharedMemory->mutexUnlock();
	m_localMutex.leave();
}

void ChangeLog::linkSelf()
{
	static const auto process_id = getpid();

	const auto state = m_sharedMemory->getHeader();

	fb_assert(state->pidLower <= PID_CAPACITY);
	fb_assert(state->pidUpper <= PID_CAPACITY);

	fb_assert(state->pidLower <= state->pidUpper);

	if (state->pidLower == state->pidUpper)
	{
		if (state->pidUpper == PID_CAPACITY)
		{
			for (ULONG i = 0; i < state->pidUpper; i++)
			{
				fb_assert(state->pids[i]);

				if (!state->pids[i] || // being a bit paranoid doesn't hurt
					state->pids[i] == process_id ||
					!ISC_check_process_existence(state->pids[i]))
				{
					state->pids[i] = process_id;
					return;
				}
			}

			status_exception::raise(Arg::Gds(isc_imp_exc));
		}

		state->pids[state->pidUpper++] = process_id;
		state->pidLower = state->pidUpper;
	}
	else
	{
		if (state->pidLower == PID_CAPACITY) // safety check
			status_exception::raise(Arg::Gds(isc_imp_exc));

		fb_assert(!state->pids[state->pidLower]);
		state->pids[state->pidLower] = process_id;

		while (++state->pidLower < state->pidUpper)
		{
			if (!state->pids[state->pidLower])
				break;
		}
	}
}

bool ChangeLog::unlinkSelf()
{
	static const auto process_id = getpid();

	const auto state = m_sharedMemory->getHeader();

	fb_assert(state->pidLower <= PID_CAPACITY);
	fb_assert(state->pidUpper <= PID_CAPACITY);

	fb_assert(state->pidLower <= state->pidUpper);
	fb_assert(state->pidUpper > 0);

	for (ULONG i = 0; i < state->pidUpper; i++)
	{
		if (state->pids[i])
		{
			if (state->pids[i] == process_id)
			{
				state->pids[i] = 0;
				state->pidLower = MIN(state->pidLower, i);

				if (i == state->pidUpper - 1)
				{
					while (state->pidUpper && !state->pids[state->pidUpper - 1])
						state->pidUpper--;
				}

				break;
			}
		}
		else if (i < state->pidLower)
		{
			state->pidLower = i;
		}
	}

	return (state->pidUpper == 0);
}

bool ChangeLog::initialize(SharedMemoryBase* shmem, bool init)
{
	if (init)
	{
		const auto state = reinterpret_cast<State*>(shmem->sh_mem_header);
		memset(state, 0, sizeof(State));

		state->init(SharedMemoryBase::SRAM_CHANGELOG_STATE, STATE_VERSION);

		state->timestamp = time(NULL);
		state->sequence = m_sequence;
	}

	return true;
}

void ChangeLog::mutexBug(int osErrorCode, const char* /*text*/)
{
	raiseError("Shared memory locking failed (error %d)", osErrorCode);
}

void ChangeLog::forceSwitch()
{
	LockGuard guard(this);

	switchActiveSegment();
}

FB_UINT64 ChangeLog::write(ULONG length, const UCHAR* data, bool sync)
{
	LockGuard guard(this);

	auto segment = getSegment(length);

	for (unsigned i = 0; i < NO_SPACE_RETRIES && !segment; i++)
	{
		if (i == 0) // log the warning just once
		{
			const string warningMsg =
				"Out of available space in journal segments, waiting for archiving...";

			logPrimaryWarning(m_config->dbName, warningMsg);
		}

		{	// scope
			LockCheckout checkout(this);
			Thread::sleep(NO_SPACE_TIMEOUT);
		}

		segment = getSegment(length);
	}

	if (!segment)
		raiseError("Out of available space in journal segments");

	const auto state = m_sharedMemory->getHeader();

	if (segment->isEmpty())
		state->timestamp = time(NULL);

	fb_assert(segment->getSequence() == state->sequence);

	segment->append(length, data);

	if (segment->getLength() > m_config->segmentSize)
	{
		segment->setState(SEGMENT_STATE_FULL);
		state->flushMark++;
		m_workingSemaphore.release();
	}

	if (sync)
	{
		if (m_config->groupFlushDelay)
		{
			const auto flushMark = state->flushMark;

			segment->addRef();

			for (ULONG delay = 0; delay < m_config->groupFlushDelay;
				delay += FLUSH_WAIT_INTERVAL)
			{
				if (state->flushMark != flushMark)
					break;

				LockCheckout checkout(this);
				Thread::sleep(FLUSH_WAIT_INTERVAL);
			}

			if (state->flushMark == flushMark)
			{
				segment->flush(true);
				state->flushMark++;
			}

			segment->release();
		}
		else
		{
			segment->flush(true);
			state->flushMark++;
		}
	}

	return state->sequence;
}

bool ChangeLog::archiveExecute(Segment* segment)
{
	if (m_config->archiveCommand.hasData())
	{
		segment->truncate();

		auto archiveCommand = m_config->archiveCommand;

		const auto filename = segment->getFileName();
		const auto pathname = m_config->journalDirectory + filename;

		const auto archpathname = m_config->archiveDirectory.hasData() ?
			m_config->archiveDirectory + filename : "";

		size_t pos;

		while ( (pos = archiveCommand.find(FILENAME_WILDCARD)) != string::npos)
			archiveCommand.replace(pos, strlen(FILENAME_WILDCARD), filename);

		while ( (pos = archiveCommand.find(PATHNAME_WILDCARD)) != string::npos)
			archiveCommand.replace(pos, strlen(PATHNAME_WILDCARD), pathname);

		while ( (pos = archiveCommand.find(ARCHPATHNAME_WILDCARD)) != string::npos)
			archiveCommand.replace(pos, strlen(ARCHPATHNAME_WILDCARD), archpathname);

		LockCheckout checkout(this);

		fb_assert(archiveCommand.hasData());
		const auto res = executeShell(archiveCommand);

		if (res)
		{
			string errorMsg;

			if (res < 0)
			{
				errorMsg.printf("Cannot execute journal archive command (error %d): %s",
								ERRNO, archiveCommand.c_str());
			}
			else
			{
				errorMsg.printf("Unexpected result (%d) while executing journal archive command: %s",
								res, archiveCommand.c_str());
			}

			logPrimaryError(m_config->dbName, errorMsg);
			return false;
		}
	}
	else if (m_config->archiveDirectory.hasData())
	{
		const auto filename = segment->getFileName();
		const auto archpathname = m_config->archiveDirectory + filename;

		struct stat statistics;
		if (os_utils::stat(archpathname.c_str(), &statistics) == 0)
		{
			if (statistics.st_size > (int) sizeof(SegmentHeader))
			{
				string warningMsg;
				warningMsg.printf("Destination journal file %s exists, it will be overwritten",
								  archpathname.c_str());

				logPrimaryWarning(m_config->dbName, warningMsg);
			}
		}

		try
		{
			LockCheckout checkout(this);

			segment->copyTo(archpathname);
		}
		catch (const status_exception& ex)
		{
			string errorMsg = "Cannot copy journal segment";
			const ISC_STATUS* status = ex.value();

			TEXT temp[BUFFER_LARGE];
			while (fb_interpret(temp, sizeof(temp), &status))
			{
				errorMsg += "\n\t";
				errorMsg += temp;
			}

			logPrimaryError(m_config->dbName, errorMsg);
			return false;
		}
		catch (...)
		{
			const string errorMsg = "Cannot copy journal segment (reason unknown)";
			logPrimaryError(m_config->dbName, errorMsg);
			return false;
		}
	}

	return true;
}

bool ChangeLog::archiveSegment(Segment* segment)
{
//	if (m_config->archiveCommand.hasData() || m_config->archiveDirectory.hasData())
	{
		segment->setState(SEGMENT_STATE_ARCH);
		segment->addRef();

		const auto success = archiveExecute(segment);

		fb_assert(segment->getState() == SEGMENT_STATE_ARCH);
		segment->setState(success ? SEGMENT_STATE_FREE : SEGMENT_STATE_FULL);
		segment->release();

		return success;
	}

	return false;
}

void ChangeLog::switchActiveSegment()
{
	for (const auto segment : m_segments)
	{
		const auto segmentState = segment->getState();

		if (segmentState == SEGMENT_STATE_USED)
		{
			if (segment->hasData())
			{
				const auto state = m_sharedMemory->getHeader();
				fb_assert(segment->getSequence() == state->sequence);

				segment->setState(SEGMENT_STATE_FULL);
				state->flushMark++;

				if (!m_shutdown)
					m_workingSemaphore.release();
			}

			break;
		}
	}
}

void ChangeLog::bgArchiver()
{
	try
	{
		// Signal about our startup
		m_startupSemaphore.release();

		while (!m_shutdown)
		{
			LockGuard guard(this);

			const auto state = m_sharedMemory->getHeader();

			for (const auto segment : m_segments)
			{
				if (segment->getState() == SEGMENT_STATE_USED)
				{
					if (segment->hasData() && m_config->archiveTimeout)
					{
						const auto delta_timestamp = time(NULL) - state->timestamp;

						if (delta_timestamp > m_config->archiveTimeout)
						{
							segment->setState(SEGMENT_STATE_FULL);
							state->flushMark++;
						}
					}

					break;
				}
			}

			Segment* lastSegment = nullptr;

			while (!m_shutdown)
			{
				bool restart = false;

				for (const auto segment : m_segments)
				{
					if (segment != lastSegment &&
						segment->getState() == SEGMENT_STATE_FULL)
					{
						lastSegment = segment;
						archiveSegment(segment);
						restart = true;
						break;
					}
				}

				if (!restart)
					break;
			}

			guard.release();

			m_workingSemaphore.tryEnter(1);
		}
	}
	catch (const Exception& ex)
	{
		iscLogException("Error in journal thread", ex);
	}

	// Signal about our exit

	try
	{
		m_cleanupSemaphore.release();
	}
	catch (const Exception& ex)
	{
		iscLogException("Error while exiting journal thread", ex);
	}
}

void ChangeLog::initSegments()
{
	clearSegments();

	const auto state = m_sharedMemory->getHeader();

	AutoPtr<PathUtils::DirIterator> iter;

	for (iter = PathUtils::newDirIterator(getPool(), m_config->journalDirectory);
		*iter; ++(*iter))
	{
		const auto filename = **iter;

		const auto fd = os_utils::openCreateSharedFile(filename.c_str(), O_BINARY);

		AutoPtr<Segment> segment(FB_NEW_POOL(getPool()) Segment(getPool(), filename, fd));

		if (!validateSegment(segment))
			continue;

		if (segment->getSequence() > state->sequence)
			segment->setState(SEGMENT_STATE_FREE);

		if (segment->getState() == SEGMENT_STATE_FREE)
		{
			segment->closeFile();

			if (segment->getSequence() + m_config->segmentCount <= state->sequence)
			{
				const PathName& fname = segment->getPathName();
				unlink(fname.c_str());
				continue;
			}
		}

		segment->addRef();
		m_segments.add(segment.release());
	}

	m_generation = state->generation;
}

void ChangeLog::clearSegments()
{
	while (m_segments.hasData())
		m_segments.pop()->release();
}

ChangeLog::Segment* ChangeLog::createSegment()
{
	const auto state = m_sharedMemory->getHeader();
	const auto sequence = state->sequence + 1;

	PathName filename;
	filename.printf(FILENAME_PATTERN, m_config->filePrefix.c_str(), sequence);
	filename = m_config->journalDirectory + filename;

	const auto fd = os_utils::openCreateSharedFile(filename.c_str(), O_EXCL | O_BINARY);

	SegmentHeader dummyHeader = {0};
	if (::write(fd, &dummyHeader, sizeof(SegmentHeader)) != sizeof(SegmentHeader))
	{
		::close(fd);
		raiseError("Journal file %s write failed (error %d)", filename.c_str(), ERRNO);
	}

	const auto segment = FB_NEW_POOL(getPool()) Segment(getPool(), filename, fd);

	segment->init(sequence, m_guid);
	segment->addRef();

	m_segments.add(segment);
	state->generation++;
	state->sequence++;

	return segment;
}

ChangeLog::Segment* ChangeLog::reuseSegment(ChangeLog::Segment* segment)
{
	// Remove segment from the list

	FB_SIZE_T pos = 0;
	if (m_segments.find(segment, pos))
		m_segments.remove(pos);
	else
		fb_assert(false);

	// Save its original filename

	const PathName orgname = segment->getPathName();

	// Release the reference (thus destroying the segment)

	segment->release();

	// Increase the sequence

	const auto state = m_sharedMemory->getHeader();
	const auto sequence = state->sequence + 1;

	// Attempt to rename the backing file

	PathName newname;
	newname.printf(FILENAME_PATTERN, m_config->filePrefix.c_str(), sequence);
	newname = m_config->journalDirectory + newname;

	// If renaming fails, then we just create a new file.
	// The old segment will be reused later in this case.
	if (::rename(orgname.c_str(), newname.c_str()) < 0)
	{
#ifdef DEV_BUILD
		const auto err = ERRNO;

		string warn;
		warn.printf("Journal file %s rename to %s failed (error %d)",
					orgname.c_str(), newname.c_str(), err);

		logPrimaryWarning(m_config->dbName, warn);
#endif
		return createSegment();
	}

	// Re-open the segment using a new name and initialize it

	const auto fd = os_utils::openCreateSharedFile(newname.c_str(), O_BINARY);

	segment = FB_NEW_POOL(getPool()) Segment(getPool(), newname, fd);

	segment->init(sequence, m_guid);
	segment->addRef();

	m_segments.add(segment);
	state->generation++;
	state->sequence++;

	return segment;
}

ChangeLog::Segment* ChangeLog::getSegment(ULONG length)
{
	Segment* activeSegment = NULL;
	Segment* freeSegment = NULL;

	FB_UINT64 minSequence = MAX_UINT64;

	for (const auto segment : m_segments)
	{
		const auto segmentState = segment->getState();
		const auto segmentSequence = segment->getSequence();

		if (segmentState == SEGMENT_STATE_USED)
		{
			if (activeSegment)
				raiseError("Multiple active journal segments found");

			activeSegment = segment;
		}
		else if (segmentState == SEGMENT_STATE_FREE)
		{
			if (!freeSegment || segmentSequence < minSequence)
			{
				freeSegment = segment;
				minSequence = segmentSequence;
			}
		}
	}

	const auto state = m_sharedMemory->getHeader();

	if (activeSegment && activeSegment->hasData() && m_config->archiveTimeout)
	{
		const size_t deltaTimestamp = time(NULL) - state->timestamp;

		if (deltaTimestamp > m_config->archiveTimeout)
		{
			activeSegment->setState(SEGMENT_STATE_FULL);
			activeSegment = NULL;
			m_workingSemaphore.release();
		}
	}

	if (activeSegment)
		return activeSegment;

	if (freeSegment)
		return reuseSegment(freeSegment);

	// Allocate one more segment if configuration allows that

	if (!m_config->segmentCount || m_segments.getCount() < m_config->segmentCount)
		return createSegment();

	return NULL;
}
