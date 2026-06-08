export const getToken = (): string | null => localStorage.getItem("token");

export const setToken = (token: string): void => localStorage.setItem("token", token);

export const removeToken = (): void => localStorage.removeItem("token");

export const getUser = () => {
  const user = localStorage.getItem("user");
  return user ? JSON.parse(user) : null;
};

export const setUser = (user: object): void =>
  localStorage.setItem("user", JSON.stringify(user));

export const removeUser = (): void => localStorage.removeItem("user");

export const isAuthenticated = (): boolean => !!getToken();

export const logout = (): void => {
  removeToken();
  removeUser();
  window.location.href = "/login";
};