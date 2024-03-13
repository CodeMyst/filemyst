export type User = {
    username: string;
    password_hash: string;
};

export type SessionInfo = {
    username: string;
};

export type SessionInfoCache = SessionInfo & {
    invalidAt: number;
};
