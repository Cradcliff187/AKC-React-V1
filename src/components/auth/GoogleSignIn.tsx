"use client"

import { Button } from "@/components/ui/button"
import { createClient } from "@/utils/supabase/client"
import { useState } from "react"

export default function GoogleSignIn() {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleSignIn = async () => {
    try {
      setIsLoading(true)
      setError(null)
      const supabase = createClient()
      const { error } = await supabase.auth.signInWithOAuth({
        provider: "google",
        options: {
          redirectTo: `${window.location.origin}/auth/callback`,
        },
      })
      if (error) throw error
    } catch (error) {
      setError(error instanceof Error ? error.message : "An error occurred")
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <Button
        onClick={handleSignIn}
        disabled={isLoading}
        className="w-full"
      >
        {isLoading ? "Loading..." : "Sign in with Google"}
      </Button>
      {error && <p className="text-red-500 text-sm">{error}</p>}
    </div>
  )
} 