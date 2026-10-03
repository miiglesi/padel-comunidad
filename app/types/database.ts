export type UserStatus = 'approved' | 'revoked'
export type UserRole = 'resident' | 'admin'

export interface Profile {
  id: string
  fullName: string
  username: string
  email: string
  block: string
  floor: string
  door: string
  status: UserStatus
  role: UserRole
  createdAt: string
  updatedAt: string
}

export interface Reservation {
  id: string
  userId: string
  block: string
  floor: string
  door: string
  startTime: string
  endTime: string
  createdAt: string
}

export interface CourtBlock {
  id: string
  createdBy: string | null
  reason: string
  startTime: string
  endTime: string
  createdAt: string
}

export interface ScheduleResponse {
  reservations: Array<{
    id: string
    user_id: string
    block: string
    floor: string
    door: string
    start_time: string
    end_time: string
    created_at: string
  }>
  blocks: Array<{
    id: string
    reason: string
    start_time: string
    end_time: string
    created_at: string
  }>
  server_time: string
}

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          full_name: string
          username: string
          email: string
          block: string
          floor: string
          door: string
          status: UserStatus
          role: UserRole
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          full_name: string
          username: string
          email: string
          block: string
          floor: string
          door: string
          status?: UserStatus
          role?: UserRole
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          full_name?: string
          username?: string
          email?: string
          block?: string
          floor?: string
          door?: string
          status?: UserStatus
          role?: UserRole
          created_at?: string
          updated_at?: string
        }
      }
      reservations: {
        Row: {
          id: string
          user_id: string
          block: string
          floor: string
          door: string
          start_time: string
          end_time: string
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          block: string
          floor: string
          door: string
          start_time: string
          end_time: string
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          block?: string
          floor?: string
          door?: string
          start_time?: string
          end_time?: string
          created_at?: string
        }
      }
      court_blocks: {
        Row: {
          id: string
          created_by: string | null
          reason: string
          start_time: string
          end_time: string
          created_at: string
        }
        Insert: {
          id?: string
          created_by?: string | null
          reason: string
          start_time: string
          end_time: string
          created_at?: string
        }
        Update: {
          id?: string
          created_by?: string | null
          reason?: string
          start_time?: string
          end_time?: string
          created_at?: string
        }
      }
    }
    Views: Record<string, never>
    Functions: {
      is_admin: {
        Args: Record<string, never>
        Returns: boolean
      }
      create_reservation: {
        Args: {
          p_start_time: string
          p_end_time: string
        }
        Returns: Database['public']['Tables']['reservations']['Row']
      }
      cancel_reservation: {
        Args: {
          p_reservation_id: string
        }
        Returns: boolean
      }
      create_court_block: {
        Args: {
          p_start_time: string
          p_end_time: string
          p_reason: string
        }
        Returns: Database['public']['Tables']['court_blocks']['Row']
      }
      remove_court_block: {
        Args: {
          p_block_id: string
        }
        Returns: boolean
      }
      admin_set_user_status: {
        Args: {
          p_user_id: string
          p_status: UserStatus
        }
        Returns: boolean
      }
      admin_update_dwelling: {
        Args: {
          p_user_id: string
          p_block: string
          p_floor: string
          p_door: string
        }
        Returns: boolean
      }
      get_court_schedule: {
        Args: Record<string, never>
        Returns: ScheduleResponse
      }
    }
  }
}
