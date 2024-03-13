import { getSession } from "$lib/server/sessionStore";
import type { Handle } from "@sveltejs/kit";

export const handle: Handle = async ({ event, resolve }) => {
    const cookies = event.cookies;
    const sid = cookies.get('filemyst');

    if (sid) {
        const session = getSession(sid);

        if (session) {
            event.locals.username = session.username;
        } else {
            cookies.delete('filemyst', { path: '/' });
        }
    }

    const response = await resolve(event);
    return response;
};
