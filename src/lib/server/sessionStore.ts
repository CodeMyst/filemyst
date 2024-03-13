import { randomBytes } from 'node:crypto';
import { deleteDbSession, deleteExpiredDbSessions, getDbSession, insertDbSession } from './db';
import type { SessionInfo, SessionInfoCache } from './models';

type Sid = string;

const sessionStore = new Map<Sid, SessionInfoCache>();

let nextCleanDate = Date.now() + 1000 * 60 * 60;

const getRandomSid = (): Sid => {
    return randomBytes(32).toString('hex');
};

export const createSession = (username: string, maxAge: number): Sid => {
    let sid: Sid = '';

    do {
        sid = getRandomSid();
    } while (sessionStore.has(sid));

    const expiresAt = Date.now() + maxAge * 1000;

    const data: SessionInfo = { username };
    insertDbSession(sid, data, expiresAt);

    sessionStore.set(sid, {
        ...data,
        invalidAt: expiresAt
    });

    if (Date.now() > nextCleanDate) {
        setTimeout(() => {
            cleanSessionStore();
        }, 5000);
    }

    return sid;
};

export const getSession = (sid: Sid): SessionInfo | undefined => {
    if (sessionStore.has(sid)) {
        return sessionStore.get(sid);
    }

    const session = getDbSession(sid);

    if (!session) return undefined;

    sessionStore.set(sid, session);

    return session;
};

export const deleteSession = (sid: Sid) => {
    sessionStore.delete(sid);
    deleteDbSession(sid);
};

const cleanSessionStore = () => {
    const now = Date.now();

    for (const [sid, session] of sessionStore) {
        if (session.invalidAt < now) {
            sessionStore.delete(sid);
        }
    }

    deleteExpiredDbSessions(now);

    nextCleanDate = Date.now() + 1000 * 60 * 60;
};
