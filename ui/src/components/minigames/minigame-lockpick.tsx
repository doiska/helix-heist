import React, { useState, useRef } from "react";
import { fetchHelix } from "../../lib/fetch-helix";
import { useUIEvent } from "../../hooks/use-ui-event";

type MinigameProps = {
  minigameId: string;
  maxAttempts: number;
  initialAttemptsRemaining: number;
};

type LockpickAttempt = {
  solved: boolean;
  complete?: boolean;
  attemptsRemaining?: number;
  message?: string;
  exhausted?: boolean;
  difference?: number;
  hint?: string;
};

export function MinigameLockpick({
  minigameId,
  maxAttempts,
  initialAttemptsRemaining,
}: MinigameProps) {
  const [angle, setAngle] = useState(0);
  const [attemptsRemaining, setAttemptsRemaining] = useState(
    initialAttemptsRemaining,
  );
  const [lastAttempt, setLastAttempt] = useState<LockpickAttempt | null>(null);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [isSolved, setIsSolved] = useState(false);

  const circleRef = useRef<HTMLDivElement>(null);

  const handleClick = async () => {
    if (isSolved || attemptsRemaining <= 0) {
      return;
    }

    console.log(`Submitting ${minigameId} attempt with angle ${angle}`);

    fetchHelix("ui.SubmitMinigameAttempt", {
      minigameId,
      attempt: angle,
    });
  };

  useUIEvent<{
    id: string;
    attempt: LockpickAttempt;
    attemptsRemaining?: number;
  } | null>("MinigameAttemptResult", (result) => {
    if (result.status !== "success" || !result.data) {
      return;
    }

    if (result.data.id !== minigameId) {
      return;
    }

    setLastAttempt(result.data.attempt);

    if (typeof result.data.attemptsRemaining === "number") {
      setAttemptsRemaining(result.data.attemptsRemaining);
    }

    if (result.data.attempt?.message) {
      setStatusMessage(result.data.attempt.message);
    }

    if (result.data.attempt?.solved) {
      setIsSolved(true);
      setStatusMessage("Unlocked!");
    } else if (result.data.attempt?.exhausted) {
      setStatusMessage("All attempts exhausted");
    }
  });

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!circleRef.current) {
      return;
    }

    const rect = circleRef.current.getBoundingClientRect();
    const centerX = rect.width / 2;
    const centerY = rect.height / 2;
    const x = e.clientX - rect.left - centerX;
    const y = e.clientY - rect.top - centerY;

    let newAngle = Math.atan2(y, x) * (180 / Math.PI) + 90;

    if (newAngle < 0) {
      newAngle += 360;
    }

    setAngle(newAngle);
  };

  return (
    <div className="absolute inset-0 flex flex-col items-center justify-center gap-4">
      <div className="text-center bg-neutral-900/60 p-3 rounded">
        <h2 className="text-white font-bold text-lg uppercase tracking-wider">
          Lockpick
        </h2>
        <p className="text-zinc-400 text-xs mt-1">
          Align the needle and click to submit
        </p>
        <p className="text-zinc-400 text-xs mt-1">
          Attempts: {attemptsRemaining}/{maxAttempts}
        </p>
        {statusMessage && (
          <p className="text-amber-400 text-xs mt-1">{statusMessage}</p>
        )}
        {lastAttempt && lastAttempt.hint && !isSolved && (
          <p className="text-sky-300 text-xs mt-1">Hint: {lastAttempt.hint}</p>
        )}
      </div>

      <div
        ref={circleRef}
        onClick={handleClick}
        onMouseMove={handleMouseMove}
        className="relative w-48 h-48 mx-auto mb-6 bg-black border-4 border-zinc-700 rounded-full select-none"
      >
        <div
          className="absolute left-1/2 w-1 h-24 bg-orange-400 origin-bottom"
          style={{
            bottom: "50%",
            transform: `translateX(-50%) rotate(${angle}deg)`,
          }}
        />

        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-3 h-3 bg-zinc-600 rounded-full border border-zinc-500" />
      </div>
    </div>
  );
}
