"use client"

import React, { useEffect, useState } from 'react'
import { useAuth } from '@/components/providers/AuthProvider'
import { Button } from '@/components/ui/button'
import { createClient } from '@/utils/supabase/client'
import { useRouter } from 'next/navigation'

export function Navigation() {
  const { session } = useAuth()
  const router = useRouter()
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  const handleSignOut = async () => {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.push('/')
  }

  // During SSR or before client-side hydration, render nothing to avoid hydration mismatch
  if (!mounted) return null

  // Only render navigation when there's an active session
  if (!session) return null

  return (
    <nav className="container mx-auto px-4 py-4 flex justify-between items-center">
      <h1 className="text-2xl font-bold">AKC Fresh</h1>
      <Button 
        variant="ghost" 
        onClick={handleSignOut}
        className="text-sm text-muted-foreground hover:text-foreground"
      >
        Sign Out
      </Button>
    </nav>
  )
} 