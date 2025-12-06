import { LogOut, Users } from "lucide-preact";
import {
  type HeistLobby as HeistLobbyType,
  type UserHeistState,
} from "../types/heist";
import { useUIEvent } from "../hooks/use-ui-event";
import { useState } from "preact/hooks";
import { fetchHelix } from "../lib/fetch-helix";

export function LobbyRoom() {
  const [userHeistState, setHeistState] = useState<UserHeistState>();
  const [heistLobbies, setHeistLobbies] = useState<HeistLobbyType[]>([]);

  useUIEvent<UserHeistState>("GetUserHeistState", (result) => {
    if (result.status === "success") {
      setHeistState(result.data);
    }
  });

  useUIEvent<HeistLobbyType[]>("GetActiveHeistInfo", (result) => {
    if (result.status === "success") {
      setHeistLobbies(result.data);
    }
  });

  const currentHeist = userHeistState?.heistId
    ? heistLobbies.find((h) => h.id === userHeistState.heistId)
    : undefined;

  const handleLeaveHeist = async () => {
    await fetchHelix("LeaveHeist");
  };

  if (!currentHeist) {
    return (
      <div className="text-center text-zinc-500 py-8 text-sm">
        Loading heist...
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="border-l-4 border-green-500 pl-4 py-2">
        <div className="text-zinc-400 text-xs uppercase tracking-wide mb-1">
          Current Operation
        </div>
        <h2 className="text-2xl font-bold text-white">{currentHeist.id}</h2>
      </div>

      <div className="grid grid-cols-3 gap-3 mt-6">
        <div className="bg-black/40 border border-zinc-800 p-4 rounded hover:border-zinc-700 transition-colors">
          <div className="text-zinc-500 text-xs uppercase tracking-wide mb-2">
            Leader
          </div>
          <div className="text-white font-bold text-sm">
            {currentHeist.leader}
          </div>
        </div>
        <div className="bg-black/40 border border-zinc-800 p-4 rounded hover:border-zinc-700 transition-colors">
          <div className="text-zinc-500 text-xs uppercase tracking-wide mb-2">
            Crew
          </div>
          <div className="text-white font-bold text-sm">
            {currentHeist.participants}
          </div>
        </div>
        <div className="bg-black/40 border border-zinc-800 p-4 rounded hover:border-zinc-700 transition-colors">
          <div className="text-zinc-500 text-xs uppercase tracking-wide mb-2">
            State
          </div>
          <div className="text-yellow-400 font-bold text-sm">
            {currentHeist.state}
          </div>
        </div>
      </div>

      <div className="mt-6">
        <div className="text-zinc-400 text-xs uppercase tracking-wide mb-3 flex items-center gap-2">
          <Users className="w-4 h-4" />
          Crew Members
        </div>
        <div className="text-zinc-400 text-sm">
          {currentHeist.participants} participant(s) in this heist
        </div>
      </div>

      <button
        onClick={handleLeaveHeist}
        className="w-full bg-red-600/80 hover:bg-red-600 text-white px-4 py-3 rounded font-bold text-sm transition-all mt-6 flex items-center justify-center gap-2 border border-red-500/30 hover:border-red-500"
      >
        <LogOut className="w-4 h-4" />
        LEAVE OPERATION
      </button>
    </div>
  );
}
