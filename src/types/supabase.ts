export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      user_profiles: {
        Row: {
          id: string
          auth_id: string | null
          email: string | null
          first_name: string | null
          last_name: string | null
          avatar_url: string | null
          role: string | null
          status: string | null
          created_at: string | null
          updated_at: string | null
        }
        Insert: {
          id?: string
          auth_id?: string | null
          email?: string | null
          first_name?: string | null
          last_name?: string | null
          avatar_url?: string | null
          role?: string | null
          status?: string | null
          created_at?: string | null
          updated_at?: string | null
        }
        Update: {
          id?: string
          auth_id?: string | null
          email?: string | null
          first_name?: string | null
          last_name?: string | null
          avatar_url?: string | null
          role?: string | null
          status?: string | null
          created_at?: string | null
          updated_at?: string | null
        }
      }
      tasks: {
        Row: {
          id: string
          title: string
          description: string | null
          project_id: string | null
          status: string
          priority: string
          due_date: string | null
          created_by_id: string | null
          assigned_to_id: string | null
          created_at: string
          updated_at: string | null
        }
        Insert: {
          id?: string
          title: string
          description?: string | null
          project_id?: string | null
          status?: string
          priority?: string
          due_date?: string | null
          created_by_id?: string | null
          assigned_to_id?: string | null
          created_at?: string
          updated_at?: string | null
        }
        Update: {
          id?: string
          title?: string
          description?: string | null
          project_id?: string | null
          status?: string
          priority?: string
          due_date?: string | null
          created_by_id?: string | null
          assigned_to_id?: string | null
          created_at?: string
          updated_at?: string | null
        }
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      is_admin: {
        Args: Record<PropertyKey, never>
        Returns: boolean
      }
      is_authenticated: {
        Args: Record<PropertyKey, never>
        Returns: boolean
      }
    }
    Enums: {
      user_role: 'admin' | 'employee' | 'client'
      task_status: 'pending' | 'in_progress' | 'completed' | 'on_hold' | 'cancelled'
      task_priority: 'low' | 'medium' | 'high' | 'urgent'
      project_status: 'draft' | 'active' | 'on_hold' | 'completed' | 'cancelled'
    }
  }
} 