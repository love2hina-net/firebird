/*
 *      PROGRAM:        JRD access method
 *      MODULE:         Attachment.h
 *      DESCRIPTION:    JRD Attachment class
 *
 * The contents of this file are subject to the Interbase Public
 * License Version 1.0 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy
 * of the License at http://www.Inprise.com/IPL.html
 *
 * Software distributed under the License is distributed on an
 * "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express
 * or implied. See the License for the specific language governing
 * rights and limitations under the License.
 *
 * The Original Code was created by Inprise Corporation
 * and its predecessors. Portions created by Inprise Corporation are
 * Copyright (C) Inprise Corporation.
 *
 * All Rights Reserved.
 * Contributor(s): ______________________________________.
 *
 */

#ifndef JRD_ATTACHMENT_H
#define JRD_ATTACHMENT_H

#include "firebird.h"
// Definition of block types for data allocation in JRD
#include "../include/fb_blk.h"
#include "../jrd/scl.h"
#include "../jrd/PreparedStatement.h"
#include "../jrd/RandomGenerator.h"
#include "../jrd/RuntimeStatistics.h"
#include "../jrd/Coercion.h"

#include "../common/classes/ByteChunk.h"
#include "../common/classes/GenericMap.h"
#include "../jrd/QualifiedName.h"
#include "../common/classes/SyncObject.h"
#include "../common/classes/array.h"
#include "../common/classes/stack.h"
#include "../common/classes/timestamp.h"
#include "../common/classes/TimerImpl.h"
#include "../common/ThreadStart.h"
#include "../common/TimeZoneUtil.h"

#include "../jrd/EngineInterface.h"
#include "../jrd/sbm.h"

#include <atomic>

#define DEBUG_LCK_LIST

namespace EDS {
	class Connection;
}

namespace Replication
{
	class TableMatcher;
}

class CharSetContainer;

namespace Jrd
{
	class thread_db;
	class Database;
	class jrd_tra;
	class jrd_req;
	class Lock;
	class jrd_file;
	class Format;
	class BufferControl;
	class SparseBitmap;
	class jrd_rel;
	class ExternalFile;
	class ViewContext;
	class IndexBlock;
	class IndexLock;
	class ArrayField;
	struct sort_context;
	class vcl;
	class TextType;
	class Parameter;
	class jrd_fld;
	class dsql_dbb;
	class PreparedStatement;
	class TraceManager;
	template <typename T> class vec;
	class jrd_rel;
	class jrd_prc;
	class Trigger;
	class TrigVector;
	class Function;
	class JrdStatement;
	class Validation;
	class Applier;


struct DSqlCacheItem
{
	DSqlCacheItem(MemoryPool& pool)
		: key(pool),
		  obsoleteMap(pool),
		  lock(nullptr),
		  locked(false)
	{
	}

	Firebird::string key;
	Firebird::GenericMap<Firebird::Pair<Firebird::Left<QualifiedName, bool> > > obsoleteMap;
	Lock* lock;
	bool locked;
};

typedef Firebird::GenericMap<Firebird::Pair<Firebird::Full<
	Firebird::string, DSqlCacheItem> > > DSqlCache;


struct DdlTriggerContext
{
	DdlTriggerContext()
		: eventType(*getDefaultMemoryPool()),
		  objectType(*getDefaultMemoryPool()),
		  objectName(*getDefaultMemoryPool()),
		  oldObjectName(*getDefaultMemoryPool()),
		  newObjectName(*getDefaultMemoryPool()),
		  sqlText(*getDefaultMemoryPool())
	{
	}

	Firebird::string eventType;
	Firebird::string objectType;
	MetaName objectName;
	MetaName oldObjectName;
	MetaName newObjectName;
	Firebird::string sqlText;
};


// Attachment flags

const ULONG ATT_no_cleanup			= 0x00001L;	// Don't expunge, purge, or garbage collect
const ULONG ATT_shutdown			= 0x00002L;	// attachment has been shutdown
const ULONG ATT_shutdown_manager	= 0x00004L;	// attachment requesting shutdown
const ULONG ATT_exclusive			= 0x00008L;	// attachment wants exclusive database access
const ULONG ATT_attach_pending		= 0x00010L;	// Indicate attachment is only pending
const ULONG ATT_exclusive_pending	= 0x00020L;	// Indicate exclusive attachment pending
const ULONG ATT_notify_gc			= 0x00040L;	// Notify garbage collector to expunge, purge ..
const ULONG ATT_garbage_collector	= 0x00080L;	// I'm a garbage collector
const ULONG ATT_cancel_raise		= 0x00100L;	// Cancel currently running operation
const ULONG ATT_cancel_disable		= 0x00200L;	// Disable cancel operations
const ULONG ATT_no_db_triggers		= 0x00400L;	// Don't execute database triggers
const ULONG ATT_manual_lock			= 0x00800L;	// Was locked manually
const ULONG ATT_async_manual_lock	= 0x01000L;	// Async mutex was locked manually
const ULONG ATT_overwrite_check		= 0x02000L;	// Attachment checks is it possible to overwrite DB
const ULONG ATT_system				= 0x04000L; // Special system attachment
const ULONG ATT_creator				= 0x08000L; // This attachment created the DB
const ULONG ATT_monitor_done		= 0x10000L; // Monitoring data is refreshed
const ULONG ATT_security_db			= 0x20000L; // Attachment used for security purposes
const ULONG ATT_mapping				= 0x40000L; // Attachment used for mapping auth block
const ULONG ATT_from_thread			= 0x80000L; // Attachment from internal special thread (sweep, crypt)
const ULONG ATT_monitor_init		= 0x100000L; // Attachment is registered in monitoring
const ULONG ATT_repl_reset			= 0x200000L; // Replication set has been reset
const ULONG ATT_replicating			= 0x400000L; // Replication is active
const ULONG ATT_resetting			= 0x800000L; // Session reset is in progress

const ULONG ATT_NO_CLEANUP			= (ATT_no_cleanup | ATT_notify_gc);

class Attachment;
class DatabaseOptions;
struct bid;


class ActiveSnapshots
{
public:
	explicit ActiveSnapshots(Firebird::MemoryPool& p);

	// Returns snapshot number given version belongs to.
	// It is not needed to maintain two versions for the same snapshot, so the latter
	// version can be garbage-collected.
	//
	// Function returns CN_ACTIVE if version was committed after we obtained
	// our list of snapshots. It means GC is not possible for this version.
	CommitNumber getSnapshotForVersion(CommitNumber version_cn);

private:
	Firebird::SparseBitmap<CommitNumber> m_snapshots;		// List of active snapshots as of the moment of time
	CommitNumber m_lastCommit;		// CN_ACTIVE here means object is not populated
	ULONG m_releaseCount;			// Release event counter when list was last updated
	ULONG m_slots_used;				// Snapshot slots used when list was last updated

	friend class TipCache;
};


//
// RefCounted part of Attachment object, placed into permanent pool
//
class StableAttachmentPart : public Firebird::RefCounted, public Firebird::GlobalStorage
{
public:
	class Sync
	{
	public:
		Sync()
			: waiters(0), threadId(0), totalLocksCounter(0), currentLocksCounter(0)
		{ }

		void enter(const char* aReason)
		{
			ThreadId curTid = getThreadId();

			if (threadId == curTid)
			{
				currentLocksCounter++;
				return;
			}

			if (threadId || !syncMutex.tryEnter(aReason))
			{
				// we have contention with another thread
				waiters.fetch_add(1, std::memory_order_relaxed);
				syncMutex.enter(aReason);
				waiters.fetch_sub(1, std::memory_order_relaxed);
			}

			threadId = curTid;
			totalLocksCounter++;
			fb_assert(currentLocksCounter == 0);
			currentLocksCounter++;
		}

		bool tryEnter(const char* aReason)
		{
			ThreadId curTid = getThreadId();

			if (threadId == curTid)
			{
				currentLocksCounter++;
				return true;
			}

			if (threadId || !syncMutex.tryEnter(aReason))
				return false;

			threadId = curTid;
			totalLocksCounter++;
			fb_assert(currentLocksCounter == 0);
			currentLocksCounter++;
			return true;
		}

		void leave()
		{
			fb_assert(currentLocksCounter > 0);

			if (--currentLocksCounter == 0)
			{
				threadId = 0;
				syncMutex.leave();
			}
		}

		bool hasContention() const
		{
			return (waiters.load(std::memory_order_relaxed) > 0);
		}

		FB_UINT64 getLockCounter() const
		{
			return totalLocksCounter;
		}

		bool locked() const
		{
			return threadId == getThreadId();
		}

		~Sync()
		{
			if (threadId == getThreadId())
			{
				syncMutex.leave();
			}
		}

	private:
		// copying is prohibited
		Sync(const Sync&);
		Sync& operator=(const Sync&);

		Firebird::Mutex syncMutex;
		std::atomic<int> waiters;
		ThreadId threadId;
		volatile FB_UINT64 totalLocksCounter;
		int currentLocksCounter;
	};

	explicit StableAttachmentPart(Attachment* handle)
		: att(handle), jAtt(NULL), shutError(0)
	{ }

	Attachment* getHandle() throw()
	{
		return att;
	}

	JAttachment* getInterface()
	{
		return jAtt;
	}

	void setInterface(JAttachment* ja)
	{
		if (jAtt)
			jAtt->detachEngine();

		jAtt = ja;
		shutError = 0;
	}

	Sync* getSync(bool useAsync = false, bool forceAsync = false)
	{
		if (useAsync && !forceAsync)
		{
			fb_assert(!mainSync.locked());
		}
		return useAsync ? &async : &mainSync;
	}

	Firebird::Mutex* getBlockingMutex()
	{
		return &blockingMutex;
	}

	void cancel()
	{
		fb_assert(async.locked());
		fb_assert(mainSync.locked());
		att = NULL;
	}

	jrd_tra* getEngineTransaction(Firebird::CheckStatusWrapper* status, Firebird::ITransaction* tra)
	{
		return getInterface()->getEngineTransaction(status, tra);
	}

	JTransaction* getTransactionInterface(Firebird::CheckStatusWrapper* status, Firebird::ITransaction* tra)
	{
		return getInterface()->getTransactionInterface(status, tra);
	}

	void manualLock(ULONG& flags, const ULONG whatLock = ATT_manual_lock | ATT_async_manual_lock);
	void manualUnlock(ULONG& flags);
	void manualAsyncUnlock(ULONG& flags);

	void setShutError(ISC_STATUS code)
	{
		if (!shutError)
			shutError = code;
	}

	ISC_STATUS getShutError() const
	{
		return shutError;
	}

	void onIdleTimer(Firebird::TimerImpl*);

private:
	Attachment* att;
	JAttachment* jAtt;
	ISC_STATUS shutError;

	// These syncs guarantee attachment existence. After releasing both of them with possibly
	// zero att_use_count one should check does attachment still exists calling getHandle().
	Sync mainSync, async;
	// This mutex guarantees attachment is not accessed by more than single external thread.
	Firebird::Mutex blockingMutex;
};

typedef Firebird::RaiiLockGuard<StableAttachmentPart::Sync> AttSyncLockGuard;
typedef Firebird::RaiiUnlockGuard<StableAttachmentPart::Sync> AttSyncUnlockGuard;

//
// the attachment block; one is created for each attachment to a database
//
class Attachment : public pool_alloc<type_att>
{
public:
	class SyncGuard
	{
	public:
		SyncGuard(StableAttachmentPart* js, const char* f, bool optional = false)
			: jStable(js)
		{
			init(f, optional);
		}

		SyncGuard(Attachment* att, const char* f, bool optional = false)
			: jStable(att ? att->getStable() : NULL)
		{
			init(f, optional);
		}

		~SyncGuard()
		{
			if (jStable)
				jStable->getSync()->leave();
		}

	private:
		// copying is prohibited
		SyncGuard(const SyncGuard&);
		SyncGuard& operator=(const SyncGuard&);

		void init(const char* f, bool optional);

		Firebird::RefPtr<StableAttachmentPart> jStable;
	};

	class GeneratorFinder
	{
	public:
		explicit GeneratorFinder(MemoryPool& pool)
			: m_objects(pool)
		{}

		void store(SLONG id, const MetaName& name)
		{
			fb_assert(id >= 0);
			fb_assert(name.hasData());

			if (id < (int) m_objects.getCount())
			{
				fb_assert(m_objects[id].isEmpty());
				m_objects[id] = name;
			}
			else
			{
				m_objects.resize(id + 1);
				m_objects[id] = name;
			}
		}

		bool lookup(SLONG id, MetaName& name)
		{
			if (id < (int) m_objects.getCount() && m_objects[id].hasData())
			{
				name = m_objects[id];
				return true;
			}

			return false;
		}

		SLONG lookup(const MetaName& name)
		{
			FB_SIZE_T pos;

			if (m_objects.find(name, pos))
				return (SLONG) pos;

			return -1;
		}

	private:
		Firebird::Array<MetaName> m_objects;
	};

	class InitialOptions
	{
	public:
		InitialOptions(MemoryPool& p)
			: bindings(p)
		{
		}

	public:
		void setInitialOptions(thread_db* tdbb, const DatabaseOptions& options);
		void resetAttachment(Attachment* attachment) const;

		CoercionArray *getBindings()
		{
			return &bindings;
		}

		const CoercionArray *getBindings() const
		{
			return &bindings;
		}

	private:
		Firebird::DecimalStatus decFloatStatus = Firebird::DecimalStatus::DEFAULT;
		CoercionArray bindings;

		USHORT originalTimeZone = Firebird::TimeZoneUtil::GMT_ZONE;
	};

	class DebugOptions
	{
	public:
		bool getDsqlKeepBlr() const
		{
			return dsqlKeepBlr;
		}

		void setDsqlKeepBlr(bool value)
		{
			dsqlKeepBlr = value;
		}

	private:
		bool dsqlKeepBlr = false;
	};

	class UseCountHolder
	{
	public:
		explicit UseCountHolder(Attachment* a)
			: att(a)
		{
			if (att)
				att->att_use_count++;
		}

		~UseCountHolder()
		{
			if (att)
				att->att_use_count--;
		}

	private:
		Attachment* att;
	};

public:
	static Attachment* create(Database* dbb, JProvider* provider);
	static void destroy(Attachment* const attachment);

	MemoryPool* const att_pool;					// Memory pool
	Firebird::MemoryStats att_memory_stats;

	Database*	att_database;				// Parent database block
	Attachment*	att_next;					// Next attachment to database
	UserId*		att_user;					// User identification
	UserId*		att_ss_user;				// User identification for SQL SECURITY actual user
	Firebird::GenericMap<Firebird::Pair<Firebird::Left<
		Firebird::MetaString, UserId*> > > att_user_ids;	// set of used UserIds
	jrd_tra*	att_transactions;			// Transactions belonging to attachment
	jrd_tra*	att_dbkey_trans;			// transaction to control db-key scope
	TraNumber	att_oldest_snapshot;		// GTT's record versions older than this can be garbage-collected
	ActiveSnapshots att_active_snapshots;	// List of currently active snapshots for GC purposes

private:
	jrd_tra*	att_sys_transaction;		// system transaction
	StableAttachmentPart* att_stable;

public:
	Firebird::SortedArray<jrd_req*> att_requests;	// Requests belonging to attachment
	Lock*		att_id_lock;				// Attachment lock (if any)
	AttNumber	att_attachment_id;			// Attachment ID
	Lock*		att_cancel_lock;			// Lock to cancel the active request
	Lock*		att_monitor_lock;			// Lock for monitoring purposes
	const ULONG	att_lock_owner_id;			// ID for the lock manager
	SLONG		att_lock_owner_handle;		// Handle for the lock manager
	ULONG		att_backup_state_counter;	// Counter of backup state locks for attachment
	SLONG		att_event_session;			// Event session id, if any
	SecurityClass*	att_security_class;		// security class for database
	SecurityClassList*	att_security_classes;	// security classes
	RuntimeStatistics	att_stats;
	RuntimeStatistics	att_base_stats;
	ULONG		att_flags;					// Flags describing the state of the attachment
	SSHORT		att_client_charset;			// user's charset specified in dpb
	SSHORT		att_charset;				// current (client or external) attachment charset
	Lock*		att_long_locks;				// outstanding two phased locks
#ifdef DEBUG_LCK_LIST
	UCHAR		att_long_locks_type;		// Lock type of the first lock in list
#endif
	std::atomic<SLONG>	att_wait_owner_handle;	// lock owner with which attachment waits currently
	vec<Lock*>*	att_compatibility_table;	// hash table of compatible locks
	Validation*	att_validation;
	Firebird::PathName	att_working_directory;	// Current working directory is cached
	Firebird::PathName	att_filename;			// alias used to attach the database
	ISC_TIMESTAMP_TZ	att_timestamp;	    // Connection date and time
	Firebird::StringMap att_context_vars;	// Context variables for the connection
	Firebird::Stack<DdlTriggerContext*> ddlTriggersContext;	// Context variables for DDL trigger event
	Firebird::string att_network_protocol;	// Network protocol used by client for connection
	Firebird::PathName att_remote_crypt;	// Name of wire crypt plugin (if any)
	Firebird::string att_remote_address;	// Protocol-specific address of remote client
	SLONG att_remote_pid;					// Process id of remote client
	ULONG att_remote_flags;					// Flags specific for server/client link
	Firebird::PathName att_remote_process;	// Process name of remote client
	Firebird::string att_client_version;	// Version of the client library
	Firebird::string att_remote_protocol;	// Details about the remote protocol
	Firebird::string att_remote_host;		// Host name of remote client
	Firebird::string att_remote_os_user;	// OS user name of remote client
	RandomGenerator att_random_generator;	// Random bytes generator
	Lock*		att_temp_pg_lock;			// temporary pagespace ID lock
	DSqlCache att_dsql_cache;	// DSQL cache locks
	Firebird::SortedArray<void*> att_udf_pointers;
	dsql_dbb* att_dsql_instance;
	bool att_in_use;						// attachment in use (can't be detached or dropped)
	int att_use_count;						// number of API calls running except of asynchronous ones
	ThreadId att_purge_tid;					// ID of thread running purge_attachment()

	EDS::Connection* att_ext_connection;	// external connection executed by this attachment
	EDS::Connection* att_ext_parent;		// external connection, parent of this attachment
	ULONG att_ext_call_depth;				// external connection call depth, 0 for user attachment
	TraceManager* att_trace_manager;		// Trace API manager

	CoercionArray att_bindings;
	CoercionArray* att_dest_bind;
	USHORT att_original_timezone;
	USHORT att_current_timezone;

	Firebird::RefPtr<Firebird::IReplicatedSession> att_replicator;
	Firebird::AutoPtr<Replication::TableMatcher> att_repl_matcher;
	Firebird::Array<Applier*> att_repl_appliers;

	enum UtilType { UTIL_NONE, UTIL_GBAK, UTIL_GFIX, UTIL_GSTAT };

	UtilType att_utility;

	/// former Database members - start

	vec<jrd_rel*>*					att_relations;			// relation vector
	Firebird::Array<jrd_prc*>		att_procedures;			// scanned procedures
	TrigVector*						att_triggers[DB_TRIGGER_MAX];
	TrigVector*						att_ddl_triggers;
	Firebird::Array<Function*>		att_functions;			// User defined functions
	GeneratorFinder					att_generators;

	Firebird::Array<JrdStatement*>	att_internal;			// internal statements
	Firebird::Array<JrdStatement*>	att_dyn_req;			// internal dyn statements
	Firebird::ICryptKeyCallback*	att_crypt_callback;		// callback for DB crypt
	Firebird::DecimalStatus			att_dec_status;			// error handling and rounding

	jrd_req* findSystemRequest(thread_db* tdbb, USHORT id, USHORT which);

	Firebird::Array<CharSetContainer*>	att_charsets;		// intl character set descriptions
	Firebird::GenericMap<Firebird::Pair<Firebird::Left<
		MetaName, USHORT> > > att_charset_ids;	// Character set ids

	void releaseIntlObjects(thread_db* tdbb);			// defined in intl.cpp
	void destroyIntlObjects(thread_db* tdbb);			// defined in intl.cpp

	void initLocks(thread_db* tdbb);
	void releaseLocks(thread_db* tdbb);
	void detachLocks();

	void releaseRelations(thread_db* tdbb);

	static int blockingAstShutdown(void*);
	static int blockingAstCancel(void*);
	static int blockingAstMonitor(void*);
	static int blockingAstReplSet(void*);

	Firebird::Array<MemoryPool*>	att_pools;		// pools

	MemoryPool* createPool();
	void deletePool(MemoryPool* pool);

	/// former Database members - end

	bool locksmith(thread_db* tdbb, SystemPrivilege sp) const;
	jrd_tra* getSysTransaction();
	void setSysTransaction(jrd_tra* trans);	// used only by TRA_init

	bool isSystem() const
	{
		return (att_flags & ATT_system);
	}

	bool isGbak() const;
	bool isRWGbak() const;
	bool isUtility() const; // gbak, gfix and gstat.

	PreparedStatement* prepareStatement(thread_db* tdbb, jrd_tra* transaction,
		const Firebird::string& text, Firebird::MemoryPool* pool = NULL);
	PreparedStatement* prepareStatement(thread_db* tdbb, jrd_tra* transaction,
		const PreparedStatement::Builder& builder, Firebird::MemoryPool* pool = NULL);

	PreparedStatement* prepareUserStatement(thread_db* tdbb, jrd_tra* transaction,
		const Firebird::string& text, Firebird::MemoryPool* pool = NULL);

	MetaName nameToMetaCharSet(thread_db* tdbb, const MetaName& name);
	MetaName nameToUserCharSet(thread_db* tdbb, const MetaName& name);
	Firebird::string stringToMetaCharSet(thread_db* tdbb, const Firebird::string& str,
		const char* charSet = NULL);
	Firebird::string stringToUserCharSet(thread_db* tdbb, const Firebird::string& str);

	void storeMetaDataBlob(thread_db* tdbb, jrd_tra* transaction,
		bid* blobId, const Firebird::string& text, USHORT fromCharSet = CS_METADATA);
	void storeBinaryBlob(thread_db* tdbb, jrd_tra* transaction, bid* blobId,
		const Firebird::ByteChunk& chunk);

	void releaseGTTs(thread_db* tdbb);
	void resetSession(thread_db* tdbb, jrd_tra** traHandle);

	void signalCancel();
	void signalShutdown(ISC_STATUS code);

	void mergeStats();
	bool hasActiveRequests() const;

	bool backupStateWriteLock(thread_db* tdbb, SSHORT wait);
	void backupStateWriteUnLock(thread_db* tdbb);
	bool backupStateReadLock(thread_db* tdbb, SSHORT wait);
	void backupStateReadUnLock(thread_db* tdbb);

	StableAttachmentPart* getStable() throw()
	{
		return att_stable;
	}

	void setStable(StableAttachmentPart *js) throw()
	{
		att_stable = js;
	}

	JAttachment* getInterface() throw();

	unsigned int getIdleTimeout() const
	{
		return att_idle_timeout;
	}

	void setIdleTimeout(unsigned int timeOut)
	{
		att_idle_timeout = timeOut;
	}

	unsigned int getActualIdleTimeout() const;

	unsigned int getStatementTimeout() const
	{
		return att_stmt_timeout;
	}

	void setStatementTimeout(unsigned int timeOut)
	{
		att_stmt_timeout = timeOut;
	}

	// evaluate new value or clear idle timer
	void setupIdleTimer(bool clear);

	// returns time when idle timer will be expired, if set
	bool getIdleTimerClock(SINT64& clock) const
	{
		if (!att_idle_timer)
			return false;

		clock = att_idle_timer->getExpireClock();
		return (clock != 0);
	}

	// batches control
	void registerBatch(JBatch* b)
	{
		att_batches.add(b);
	}

	void deregisterBatch(JBatch* b)
	{
		att_batches.findAndRemove(b);
	}

	UserId* getUserId(const Firebird::MetaString& userName);

	const Firebird::MetaString& getUserName(const Firebird::MetaString& emptyName = "") const
	{
		return att_user ? att_user->getUserName() : emptyName;
	}

	const Firebird::MetaString& getSqlRole(const Firebird::MetaString& emptyName = "") const
	{
		return att_user ? att_user->getSqlRole() : emptyName;
	}

	const UserId* getEffectiveUserId() const
	{
		if (att_ss_user)
			return att_ss_user;
		return att_user;
	}

	const Firebird::MetaString& getEffectiveUserName(const Firebird::MetaString& emptyName = "") const
	{
		const auto user = getEffectiveUserId();
		return user ? user->getUserName() : emptyName;
	}

	void setInitialOptions(thread_db* tdbb, DatabaseOptions& options, bool newDb);
	const CoercionArray* getInitialBindings() const
	{
		return att_initial_options.getBindings();
	}

	DebugOptions& getDebugOptions()
	{
		return att_debug_options;
	}

	void checkReplSetLock(thread_db* tdbb);
	void invalidateReplSet(thread_db* tdbb, bool broadcast);

	JProvider* getProvider()
	{
		fb_assert(att_provider);
		return att_provider;
	}

private:
	Attachment(MemoryPool* pool, Database* dbb, JProvider* provider);
	~Attachment();

	unsigned int att_idle_timeout;		// seconds
	unsigned int att_stmt_timeout;		// milliseconds

	typedef Firebird::TimerWithRef<StableAttachmentPart> IdleTimer;
	Firebird::RefPtr<IdleTimer> att_idle_timer;

	Firebird::Array<JBatch*> att_batches;
	InitialOptions att_initial_options;	// Initial session options
	DebugOptions att_debug_options;

	Lock* att_repl_lock;				// Replication set lock
	JProvider* att_provider;	// Provider which created this attachment
};


inline bool Attachment::locksmith(thread_db* tdbb, SystemPrivilege sp) const
{
	const auto user = getEffectiveUserId();
	return (user && user->locksmith(tdbb, sp));
}

inline jrd_tra* Attachment::getSysTransaction()
{
	return att_sys_transaction;
}

inline void Attachment::setSysTransaction(jrd_tra* trans)
{
	att_sys_transaction = trans;
}

// Connection is from GBAK
inline bool Attachment::isGbak() const
{
	return (att_utility == UTIL_GBAK);
}

// Gbak changes objects when it's restoring (creating) a db.
// Other attempts are fake. Gbak reconnects to change R/O status and other db-wide settings,
// but it doesn't modify generators or tables that seconds time.
inline bool Attachment::isRWGbak() const
{
	return (isGbak() && (att_flags & ATT_creator));
}

// Any of the three original utilities: gbak, gfix or gstat.
inline bool Attachment::isUtility() const
{
	return (att_utility != UTIL_NONE);
}

// This class holds references to all attachments it contains

class AttachmentsRefHolder
{
	friend class Iterator;

public:
	class Iterator
	{
	public:
		explicit Iterator(AttachmentsRefHolder& list)
			: m_list(list), m_index(0)
		{}

		StableAttachmentPart* operator*()
		{
			if (m_index < m_list.m_attachments.getCount())
				return m_list.m_attachments[m_index];

			return NULL;
		}

		void operator++()
		{
			m_index++;
		}

		void remove()
		{
			if (m_index < m_list.m_attachments.getCount())
			{
				m_list.m_attachments[m_index]->release();
				m_list.m_attachments.remove(m_index);
			}
		}

	private:
		// copying is prohibited
		Iterator(const Iterator&);
		Iterator& operator=(const Iterator&);

		AttachmentsRefHolder& m_list;
		FB_SIZE_T m_index;
	};

	explicit AttachmentsRefHolder(MemoryPool& p)
		: m_attachments(p)
	{}

	AttachmentsRefHolder()
		: m_attachments(*MemoryPool::getContextPool())
	{}

	AttachmentsRefHolder& operator=(const AttachmentsRefHolder& other)
	{
		clear();

		for (FB_SIZE_T i = 0; i < other.m_attachments.getCount(); i++)
			add(other.m_attachments[i]);

		return *this;
	}

	void clear()
	{
		while (m_attachments.hasData())
		{
			m_attachments.pop()->release();
		}
	}

	~AttachmentsRefHolder()
	{
		clear();
	}

	void add(StableAttachmentPart* jAtt)
	{
		if (jAtt)
		{
			jAtt->addRef();
			m_attachments.add(jAtt);
		}
	}

	bool hasData() const
	{
		return m_attachments.hasData();
	}

private:
	AttachmentsRefHolder(const AttachmentsRefHolder&);

	Firebird::HalfStaticArray<StableAttachmentPart*, 128> m_attachments;
};

// Class used in system background threads

class SysStableAttachment : public StableAttachmentPart
{
public:
	explicit SysStableAttachment(Attachment* handle);

	void initDone();

	virtual ~SysStableAttachment()
	{
		Attachment* attachment = getHandle();
		if (attachment)
		{
			destroy(attachment);
		}
	}

private:
	void destroy(Attachment* attachment);

	// "public" interface for internal (system) attachment
	Firebird::RefPtr<JAttachment> m_JAttachment;
};

} // namespace Jrd

#endif // JRD_ATTACHMENT_H
