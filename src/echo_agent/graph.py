import asyncio
import json
from typing import Annotated, TypedDict

from langchain_core.messages import AIMessage, AnyMessage
from langgraph.graph import StateGraph, add_messages


class State(TypedDict):
    messages: Annotated[list[AnyMessage], add_messages]


async def echo(state: State) -> dict[str, list[AIMessage]]:
    content = state["messages"][-1].content if state.get("messages") else ""
    try:
        request = json.loads(content)
    except (json.JSONDecodeError, TypeError):
        request = {"message": content}

    delay = min(max(float(request.get("delay", 0)), 0), 120)
    await asyncio.sleep(delay)
    return {
        "messages": [
            AIMessage(
                content=json.dumps(
                    {
                        "echo": request.get("message", content),
                        "delay": delay,
                        "status": "completed",
                    },
                    sort_keys=True,
                )
            )
        ]
    }


builder = StateGraph(State)
builder.add_node("echo", echo)
builder.set_entry_point("echo")
builder.set_finish_point("echo")
graph = builder.compile()
