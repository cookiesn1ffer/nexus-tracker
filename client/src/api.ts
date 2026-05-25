const BASE_URL = ''; // Relative paths to use proxy in dev and same-host routing in prod

async function request(endpoint: string, options: RequestInit = {}) {
  const token = localStorage.getItem('nexus_token');
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...(token ? { 'Authorization': `Bearer ${token}` } : {})
  };

  const response = await fetch(`${BASE_URL}${endpoint}`, {
    ...options,
    headers: {
      ...headers,
      ...options.headers
    }
  });

  if (response.status === 401) {
    localStorage.removeItem('nexus_token');
    // Use a small delay to allow state to settle before reload if needed, 
    // or just let the app handle the missing user state.
    // However, window.location.reload() is a hard reset which is safe.
    window.location.reload();
    return;
  }

  let data;
  try {
    data = await response.json();
  } catch (err) {
    if (!response.ok) {
      throw new Error(`Error ${response.status}: ${response.statusText}`);
    }
    return null;
  }

  if (!response.ok) {
    throw new Error(data?.error || 'Something went wrong');
  }
  return data;
}

export const api = {
  get: (endpoint: string) => request(endpoint, { method: 'GET' }),
  post: (endpoint: string, body: any) => request(endpoint, {
    method: 'POST',
    body: JSON.stringify(body)
  }),
  delete: (endpoint: string) => request(endpoint, { method: 'DELETE' })
};
