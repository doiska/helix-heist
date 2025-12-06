import { useState } from "preact/hooks";
import { useUIEvent } from "../hooks/use-ui-event";
import { type HeistLobby as HeistLobbyType } from "../types/heist";
import { fetchHelix } from "../lib/fetch-helix";

export function LobbyList() {
  const [heistLobbies, setHeistLobbies] = useState<HeistLobbyType[]>([]);

  useUIEvent<HeistLobbyType[]>("GetActiveHeistInfo", (result) => {
    if (result.status === "success") {
      setHeistLobbies(result.data);
    }
  });

  const handleCreateHeist = async () => {
    await fetchHelix("CreateHeist");
  };

  const handleJoinHeist = async (heistId: string) => {
    await fetchHelix("JoinHeist", heistId);
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-4">
        <div className="text-zinc-300 text-xs uppercase tracking-wide font-bold">
          Available Operations ({heistLobbies.length})
        </div>
        <button
          onClick={handleCreateHeist}
          className="inline-flex items-center justify-center text-white bg-emerald-600 shadow rounded"
        >
          Start a new Heist
        </button>
      </div>

      <div className="space-y-2">
        {heistLobbies.length === 0 ? (
          <div className="text-center text-zinc-500 py-8 text-sm">
            No operations available
          </div>
        ) : (
          heistLobbies.map((heist) => (
            <div
              key={heist.id}
              className="bg-black/40 border border-zinc-800 hover:border-zinc-600 hover:bg-black/60 rounded px-4 py-3 transition-all group"
            >
              <div className="flex items-center justify-between gap-4">
                <div className="flex-1 min-w-0">
                  <div className="text-white font-bold text-sm truncate">
                    {heist.id}
                  </div>
                  <div className="text-zinc-400 text-xs mt-1">
                    Led by{" "}
                    <span className="text-zinc-300 font-mono">
                      {heist.leader}
                    </span>
                  </div>
                </div>

                <div className="flex items-center gap-6 text-sm">
                  <div className="text-center">
                    <div className="text-zinc-500 text-xs uppercase">Crew</div>
                    <div className="text-white font-bold">
                      {heist.participants}
                    </div>
                  </div>
                  <div className="text-center">
                    <div className="text-zinc-500 text-xs uppercase">State</div>
                    <div className="text-yellow-400 font-bold">
                      {heist.state}
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  <button
                    disabled={status === "loading" || !heist.canJoin}
                    onClick={() => handleJoinHeist(heist.id)}
                    className="bg-blue-600/80 hover:bg-blue-600 disabled:bg-zinc-800 disabled:text-zinc-600 text-white px-4 py-2 rounded font-bold text-xs transition-all border border-blue-500/30 hover:border-blue-500 disabled:border-zinc-700"
                  >
                    JOIN
                  </button>
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
