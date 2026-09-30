export const syncPolicy=Object.freeze({
  maxAttempts:5,
  baseDelayMs:1000,
  maxDelayMs:30000,
});
export const isRetryable=({status=0,code}={})=>status===0||status===408||status===429||status>=500||code==='TIMEOUT'||code==='NETWORK_ERROR';
export const retryDelay=(attempt)=>{
  const exponential=Math.min(syncPolicy.maxDelayMs,syncPolicy.baseDelayMs*(2**Math.max(0,attempt-1)));
  const jitter=Math.floor(Math.random()*Math.max(1,exponential*.25));
  return exponential+jitter;
};
export const syncStates=Object.freeze({DRAFT:'draft',PENDING:'pending',SYNCING:'syncing',SYNCED:'synced',CONFLICT:'conflict',FAILED:'failed'});
