export const login = async (username: string, password: string): Promise<boolean> => {
  const res = await fetch(`${import.meta.env.VITE_API_URL}/login`, {
    method: 'post',
    body: JSON.stringify({ username, password })
  });

  if (res.ok) {
    const json = await res.json();
    localStorage.setItem('filemyst-token', json['access_token']);
  }

  return res.ok;
};
