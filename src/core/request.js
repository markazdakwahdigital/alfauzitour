import{config}from'./config';
export const createRequestId=()=>globalThis.crypto?.randomUUID?.()||`req-${Date.now()}-${Math.random().toString(36).slice(2)}`;
export const createIdempotencyKey=(scope='mutation')=>`${scope}:${createRequestId()}`;

export class ApiError extends Error{
  constructor(message,{status=0,code='NETWORK_ERROR',details=null,requestId=null}={}){
    super(message);this.name='ApiError';this.status=status;this.code=code;this.details=details;this.requestId=requestId;
  }
}

export async function apiRequest(path,{method='GET',body,token,idempotencyKey,expectedVersion,signal}={}){
  if(!config.apiBaseUrl)throw new ApiError('Backend API belum dikonfigurasi',{code:'BACKEND_NOT_CONFIGURED'});
  const requestId=createRequestId();
  const controller=new AbortController();
  const timer=setTimeout(()=>controller.abort(),config.requestTimeoutMs);
  const abort=()=>controller.abort(); signal?.addEventListener?.('abort',abort,{once:true});
  try{
    const headers={'Accept':'application/json','X-Request-ID':requestId};
    if(body!==undefined)headers['Content-Type']='application/json';
    if(token)headers.Authorization=`Bearer ${token}`;
    if(idempotencyKey)headers['Idempotency-Key']=idempotencyKey;
    if(expectedVersion!==undefined)headers['If-Match']=String(expectedVersion);
    const response=await fetch(`${config.apiBaseUrl}${path}`,{method,headers,body:body===undefined?undefined:JSON.stringify(body),signal:controller.signal});
    const payload=response.status===204?null:await response.json().catch(()=>null);
    if(!response.ok)throw new ApiError(payload?.message||`Request gagal (${response.status})`,{status:response.status,code:payload?.code||'API_ERROR',details:payload?.details,requestId});
    return{data:payload,requestId,status:response.status};
  }catch(error){
    if(error instanceof ApiError)throw error;
    throw new ApiError(error?.name==='AbortError'?'Request timeout':'Koneksi ke server gagal',{code:error?.name==='AbortError'?'TIMEOUT':'NETWORK_ERROR',requestId});
  }finally{
    clearTimeout(timer);signal?.removeEventListener?.('abort',abort);
  }
}
