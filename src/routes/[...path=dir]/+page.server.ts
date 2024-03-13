import { error, type Cookies, fail, redirect } from '@sveltejs/kit';
import { fileExists, getEntries } from '../../files';
import type { Actions, PageServerLoad } from './$types';
import { createSession, deleteSession } from '$lib/server/sessionStore';
import { checkUserCredentials } from '$lib/server/db';

export const load: PageServerLoad = async ({ params }) => {
    if (!fileExists(params.path)) error(404);

    const entries = getEntries(params.path);

    return { path: params.path, entries };
};

export const actions: Actions = {
    login: async ({ request, cookies }) => {
        const data = await request.formData();
        const username = data.get('username')?.toString();
        const password = data.get('password')?.toString();

        if (!username || !password) return fail(400);

        const ok = await checkUserCredentials(username, password);

        if (!ok) return fail(401);

        login(cookies, username);

        throw redirect(303, '/');
    },

    logout: async ({ cookies }) => {
        const sid = cookies.get('filemyst');

        if (sid) {
            cookies.delete('filemyst', { path: '/' });
            deleteSession(sid);
        }

        throw redirect(303, '/');
    }
};

const login = (cookies: Cookies, username: string) => {
    const maxAge = 1000 * 60 * 60 * 24 * 30;
    const sid = createSession(username, maxAge);
    cookies.set('filemyst', sid, { maxAge, path: '/', httpOnly: true });
};
