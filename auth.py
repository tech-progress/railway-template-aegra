import hmac
import os

from langgraph_sdk import Auth


auth = Auth()
api_key = os.environ.get("AEGRA_API_KEY")
if not api_key:
    raise RuntimeError("AEGRA_API_KEY is required")


@auth.authenticate
async def authenticate(headers: dict[str, str]) -> dict[str, object]:
    authorization = headers.get("authorization", "") or headers.get("Authorization", "")
    supplied = authorization[7:] if authorization.startswith("Bearer ") else ""
    if not supplied or not hmac.compare_digest(supplied, api_key):
        raise Auth.exceptions.HTTPException(status_code=401, detail="Invalid bearer token")

    return {
        "identity": "railway-user",
        "display_name": "Railway user",
        "permissions": ["read", "write"],
        "is_authenticated": True,
    }
