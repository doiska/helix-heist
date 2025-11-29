export interface HeistLobby {
  id: string;
  state: string;
  participants: number;
  leader: string;
  canJoin: boolean;
}

export interface UserHeistState {
  inHeist: boolean;
  heistId: string | null;
}
