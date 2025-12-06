import { useState } from "preact/hooks";
import { type UserHeistState } from "../types/heist";
import { LobbyList } from "./lobby-list";
import { LobbyRoom } from "./lobby-room";
import { useUIEvent } from "../hooks/use-ui-event";

interface HeistLobbyProps {
  onBack?: () => void;
}

export function HeistLobby({ onBack }: HeistLobbyProps) {
  const [userHeistState, setHeistState] = useState<UserHeistState>();

  useUIEvent<UserHeistState>("UpdateUserHeistState", (result) => {
    if (result.status === "success") {
      setHeistState(result.data);
    }
  });

  return (
    <div className="fixed inset-0 flex items-center justify-center bg-black/80">
      <div className="w-[80vw] h-[80vh] bg-zinc-950 rounded-lg border border-zinc-800 shadow-2xl flex flex-col overflow-hidden">
        <div className="h-20 border-b border-zinc-800 bg-linear-to-r from-black to-zinc-900 px-8 flex items-center justify-between">
          <div>
            <div className="text-white font-bold text-lg">Heist Lobbies</div>
            {onBack && (
              <button
                onClick={onBack}
                className="text-zinc-400 hover:text-white text-xs font-bold uppercase tracking-wider transition-colors px-4 py-2 border border-zinc-700 hover:border-zinc-500 rounded"
              >
                Back
              </button>
            )}
          </div>
        </div>

        <div className="flex-1 overflow-y-auto px-8 py-6">
          {userHeistState?.inHeist ? <LobbyRoom /> : <LobbyList />}
        </div>
      </div>
    </div>
  );
}
