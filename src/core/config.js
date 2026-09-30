const trimSlash=v=>String(v||'').replace(/\/$/,'');
export const config=Object.freeze({
  apiBaseUrl:trimSlash(import.meta.env.VITE_API_BASE_URL||''),
  appVersion:import.meta.env.VITE_APP_VERSION||'dev',
  requestTimeoutMs:Number(import.meta.env.VITE_REQUEST_TIMEOUT_MS||12000),
});
export const hasBackend=()=>Boolean(config.apiBaseUrl);
