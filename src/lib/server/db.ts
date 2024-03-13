import Database from 'better-sqlite3';
import bcrypt from 'bcrypt';
import { ADMIN_PASSWORD, ADMIN_USERNAME } from '$env/static/private';
import type { SessionInfo, SessionInfoCache } from './models';

const db = new Database('./filemyst.sqlite', { verbose: console.log });

const createTables = () => {
    db.exec(`
        create table if not exists users (
            username text not null primary key unique,
            password text not null,
            created_at datetime not null default CURRENT_TIMESTAMP
        )
    `);

    db.exec(`
        create table if not exists sessions (
            id text not null primary key unique,
            created_at integer not null default (strftime('%s', 'now') * 1000),
            expires_at integer not null,
            data text not null
        )
    `);
};

const adminExists = (): boolean => {
    const sql = 'select username from users where username = $username';

    const stmnt = db.prepare(sql);

    return !!stmnt.get({ username: ADMIN_USERNAME });
};

const createAdminUser = async () => {
    if (adminExists()) return;

    const sql = 'insert into users (username, password) values ($username, $password)';

    const hashedPassword = await bcrypt.hash(ADMIN_PASSWORD, 12);

    const stmnt = db.prepare(sql);

    stmnt.run({ username: ADMIN_USERNAME, password: hashedPassword });
};

export const checkUserCredentials = async (username: string, password: string) => {
    const sql = 'select password from users where username = $username';

    const stmnt = db.prepare(sql);
    const row = stmnt.get({ username }) as { password: string };

    if (row) {
        return await bcrypt.compare(password, row.password)
    } else {
        await bcrypt.hash(password, 12);
        return false;
    }
};

export const getDbSession = (sid: string): SessionInfoCache | undefined => {
    const sql = 'select data, expires_at from sessions where id = $sid';

    const stmnt = db.prepare(sql);
    const row = stmnt.get({ sid }) as { data: string; expires_at: number };

    if (!row) return undefined;

    const data = JSON.parse(row.data);
    data.expires_at = row.expires_at;

    return data as SessionInfoCache;
};

export const insertDbSession = (sid: string, sessionInfo: SessionInfo, expiresAt: number) => {
    const sql = 'insert into sessions (id, expires_at, data) values ($sid, $expires_at, $data)';

    const stmnt = db.prepare(sql);
    stmnt.run({ sid, expires_at: expiresAt, data: JSON.stringify(sessionInfo) });
};

export const deleteExpiredDbSessions = (now: number) => {
    const sql = 'delete from sessions where expires_at < $now';

    const stmnt = db.prepare(sql);
    stmnt.run({ now });
};

export const deleteDbSession = (sid: string) => {
    const sql = 'delete from sessions where id = $sid';

    const stmnt = db.prepare(sql);

    stmnt.run({ sid });
};

createTables();
await createAdminUser();
