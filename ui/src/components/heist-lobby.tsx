import { useClientQuery } from "../hooks/utils/use-client-query";
import { type UserHeistState } from "../types/heist";
import LobbyList from "./lobby-list";
import LobbyRoom from "./lobby-room";

interface HeistLobbyProps {
  onBack?: () => void;
}

export default function HeistLobby({ onBack }: HeistLobbyProps) {
  const { data: userHeistState } = useClientQuery<UserHeistState>({
    event: "GetUserHeistState",
    queryKey: ["heist", "user"],
  });

  return (
    <div className="fixed inset-0 flex items-center justify-center bg-black/80">
      <div className="w-[80vw] h-[80vh] bg-zinc-950 rounded-lg border border-zinc-800 shadow-2xl flex flex-col overflow-hidden">
        <div className="h-20 border-b border-zinc-800 bg-gradient-to-r from-black to-zinc-900 px-8 flex items-center justify-between">
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

        <div className="flex-1 overflow-y-auto px-8 py-6">
          {userHeistState?.inHeist ? <LobbyRoom /> : <LobbyList />}
        </div>
      </div>
    </div>
  );
}
