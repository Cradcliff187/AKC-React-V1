import { createClient } from "@/utils/supabase/server"
import { cookies } from "next/headers"
import { NextResponse } from "next/server"

export async function GET(request: Request) {
  const requestUrl = new URL(request.url)
  const code = requestUrl.searchParams.get("code")

  if (code) {
    const cookieStore = cookies()
    const supabase = createClient(cookieStore)
    
    try {
      const { error } = await supabase.auth.exchangeCodeForSession(code)
      if (error) {
        console.error("Auth callback error:", error)
        return NextResponse.redirect(new URL("/?error=auth_callback_failed", requestUrl.origin))
      }
    } catch (error) {
      console.error("Auth callback error:", error)
      return NextResponse.redirect(new URL("/?error=auth_callback_failed", requestUrl.origin))
    }
  }

  // URL to redirect to after sign in process completes
  return NextResponse.redirect(new URL("/dashboard", requestUrl.origin))
} 