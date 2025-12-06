import { useEffect, useState } from "preact/hooks";
import { useUIEvent } from "./hooks/use-ui-event";
import { MinigameLockpick } from "./components/minigames/minigame-lockpick";
import { LobbyList } from "./components/lobby-list";
import { fetchHelix } from "./lib/fetch-helix";
import type { HeistState } from "./types/heist";

type MinigameBase = {
  id: string;
  type: "door" | "vault";
  minigameType: "lockpick" | "pattern";
  timeLimit: number;
  attemptsRemaining: number;
  maxAttempts: number;
};

type LobbyState = {
  id: string;
  state: HeistState;
  participants: string[];
  leader: string;
  canJoin: boolean;
};

export function App() {
  const [isLoaded, setLoaded] = useState(false);
  const [currentMinigame, setCurrentMinigame] = useState<MinigameBase | null>(
    null,
  );

  const [heistLobbies, setLobbies] = useState<LobbyState[] | null>(null);
  const [currentHeist, setCurrentHeist] = useState<LobbyState | null>(null);

  useUIEvent<MinigameBase | null>("StartMinigame", (result) => {
    if (result.status === "success") {
      setCurrentMinigame(result.data);
    }
  });

  useUIEvent<LobbyState[] | null>("ShowLobby", (result) => {
    if (result.status === "success") {
      console.log(JSON.stringify(result));
      setLobbies(result.data);
    }
  });

  useUIEvent<LobbyState | null>("HeistUpdate", (result) => {
    if (result.status === "success") {
      setCurrentHeist(result.data);
    }
  });

  useUIEvent("HideMinigame", () => setCurrentMinigame(null));
  useUIEvent("Loaded", () => setLoaded(true));

  useEffect(() => {
    const abortController = new AbortController();

    document.addEventListener(
      "keydown",
      (event: KeyboardEvent) => {
        if (event.key === "Escape") {
          setLobbies(null);
          fetchHelix("ui.Close");
        }
      },
      {
        signal: abortController.signal,
      },
    );

    return () => {
      abortController.abort();
    };
  }, []);

  if (!isLoaded) {
    return null;
  }

  if (currentMinigame && currentMinigame.minigameType === "lockpick") {
    return (
      <MinigameLockpick
        minigameId={currentMinigame.id}
        maxAttempts={currentMinigame.maxAttempts}
        initialAttemptsRemaining={currentMinigame.attemptsRemaining}
      />
    );
  }

  if (heistLobbies) {
    return <LobbyList lobbies={heistLobbies} />;
  }

  return null;
}
