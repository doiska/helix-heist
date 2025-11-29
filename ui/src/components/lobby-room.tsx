import { LogOut, Users } from "lucide-preact";
import { useClientQuery } from "../hooks/utils/use-client-query";
import { useUIMutation } from "../hooks/utils/use-client-mutation";
import { useUIEvent } from "../hooks/utils/use-client-event";
import { useQueryCache } from "../hooks/utils/query-cache";
import {
  type HeistLobby as HeistLobbyType,
  type UserHeistState,
} from "../types/heist";

export function LobbyRoom({ onStateUpdate }: { onStateUpdate: () => void }) {
  const queryCache = useQueryCache();

  const { data: userHeistState, refetch } = useClientQuery<UserHeistState>({
    event: "GetUserHeistState",
    queryKey: ["heist", "user"],
  });

  const { data: heistLobbies = [] } = useClientQuery<HeistLobbyType[]>({
    event: "GetActiveHeistInfo",
    queryKey: ["heist", "lobbies"],
  });

  const currentHeist = userHeistState?.heistId
    ? heistLobbies.find((h) => h.id === userHeistState.heistId)
    : undefined;

  const { mutate: leaveHeistMutation } = useUIMutation();

  useUIEvent("HeistUpdate", (data: any) => {
    if (data.deleted) {
      queryCache.setQueryData<UserHeistState>(["heist", "user"], {
        inHeist: false,
        heistId: null,
      });
      return;
    }

    queryCache.setQueryData<HeistLobbyType[]>(
      ["heist", "lobbies"],
      (old = []) =>
        old.map((h) =>
          h.id === data.heistId
            ? {
                id: data.heistId,
                state: data.state,
                participants: data.participants.length,
                leader: data.leader,
                canJoin: data.canJoin,
              }
            : h,
        ),
    );
  });

  const handleLeaveHeist = async () => {
    await leaveHeistMutation("LeaveHeist", undefined);
    onStateUpdate();
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
