"use client"

import { useEffect, useState } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { createClient } from '@/utils/supabase/client'
import { useRouter } from 'next/navigation'
import { Input } from "@/components/ui/input"
import { Checkbox } from "@/components/ui/checkbox"

interface Task {
  id: string
  name: string
  status?: string
  project_id?: string
  priority?: string
  due_date?: string
}

export default function Dashboard() {
  const [user, setUser] = useState<any>(null)
  const [tasks, setTasks] = useState<Task[]>([])
  const [newTask, setNewTask] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const router = useRouter()

  // Fetch user and tasks
  useEffect(() => {
    const fetchData = async () => {
      try {
        // Get user
        console.log('Checking authentication status...')
        const supabase = createClient()
        const { data: { user }, error: userError } = await supabase.auth.getUser()
        console.log('Auth check result:', { user, error: userError })
        
        if (userError) throw userError
        if (!user) {
          console.log('No user found, redirecting to login...')
          router.push('/')
          return
        }
        console.log('User authenticated:', user)
        setUser(user)

        // Get tasks
        console.log('Fetching tasks...')
        const { data: tasks, error: tasksError } = await supabase
          .from('tasks')
          .select('*')
          .order('due_date', { ascending: true })
        
        if (tasksError) {
          console.error('Error fetching tasks:', tasksError)
          throw tasksError
        }
        console.log('Tasks fetched successfully:', tasks)
        setTasks(tasks || [])
      } catch (error) {
        console.error('Error in fetchData:', error)
        setError(error instanceof Error ? error.message : 'An error occurred')
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [router])

  // Add new task
  const handleAddTask = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newTask.trim()) return

    try {
      const supabase = createClient()
      // Check if user is authenticated
      const { data: { user: currentUser } } = await supabase.auth.getUser()
      if (!currentUser) {
        setError('You must be logged in to create tasks')
        router.push('/')
        return
      }

      console.log('Attempting to create task with title:', newTask.trim())
      setError(null) // Clear any previous errors
      
      const { data, error } = await supabase
        .from('tasks')
        .insert([
          {
            name: newTask.trim()
          }
        ])
        .select()
        .single()

      if (error) {
        console.error('Task creation error:', {
          message: error.message,
          details: error.details,
          hint: error.hint,
          code: error.code
        })
        throw error
      }
      
      console.log('Task created successfully:', data)
      setTasks([data, ...tasks])
      setNewTask('')
    } catch (error) {
      console.error('Error details:', error)
      if (error instanceof Error) {
        setError(`Failed to add task: ${error.message}`)
      } else {
        setError('Failed to add task. Please try again.')
      }
    }
  }

  // Toggle task status
  const handleToggleTask = async (task: Task) => {
    try {
      const supabase = createClient()
      const newStatus = task.status === 'completed' ? 'pending' : 'completed'
      const { error } = await supabase
        .from('tasks')
        .update({ status: newStatus })
        .eq('id', task.id)

      if (error) throw error
      setTasks(tasks.map(t => 
        t.id === task.id ? { ...t, status: newStatus } : t
      ))
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to update task')
    }
  }

  // Delete task
  const handleDeleteTask = async (id: string) => {
    try {
      const supabase = createClient()
      const { error } = await supabase
        .from('tasks')
        .delete()
        .eq('id', id)

      if (error) throw error
      setTasks(tasks.filter(t => t.id !== id))
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to delete task')
    }
  }

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-[60vh]">
        <p>Loading...</p>
      </div>
    )
  }

  return (
    <div className="space-y-8">
      <Card>
        <CardHeader>
          <CardTitle>Add New Task</CardTitle>
          <CardDescription>Enter a task name and press Enter or click Add</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleAddTask} className="flex gap-2">
            <Input
              type="text"
              value={newTask}
              onChange={(e) => setNewTask(e.target.value)}
              placeholder="Enter task name..."
              className="flex-1"
            />
            <Button type="submit">Add</Button>
          </form>
          {error && <p className="text-red-500 mt-2">{error}</p>}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Your Tasks</CardTitle>
          <CardDescription>Manage your tasks here</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {tasks.length === 0 ? (
              <p className="text-muted-foreground">No tasks yet. Add one above!</p>
            ) : (
              tasks.map((task) => (
                <div key={task.id} className="flex items-center gap-2">
                  <Checkbox
                    checked={task.status === 'completed'}
                    onCheckedChange={() => handleToggleTask(task)}
                  />
                  <span className={task.status === 'completed' ? 'line-through text-muted-foreground' : ''}>
                    {task.name}
                  </span>
                  <Button
                    variant="ghost"
                    size="sm"
                    className="ml-auto"
                    onClick={() => handleDeleteTask(task.id)}
                  >
                    Delete
                  </Button>
                </div>
              ))
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  )
} 