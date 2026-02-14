local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
  -- Next.js App Router Page
  s("npage", fmt([[
'use client'

export default function {}Page() {{
  return (
    <div>
      <h1>{}</h1>
      {}
    </div>
  )
}}
]], { i(1, "Home"), i(2, "Page Title"), i(0) })),

  -- Next.js Server Component
  s("nserver", fmt([[
export default async function {}() {{
  {}

  return (
    <div>
      {}
    </div>
  )
}}
]], { i(1, "ServerComponent"), i(2, "// fetch data"), i(0) })),

  -- Next.js API Route
  s("napi", fmt([[
import {{ NextRequest, NextResponse }} from 'next/server'

export async function GET(request: NextRequest) {{
  {}
  return NextResponse.json({{ {} }})
}}
]], { i(1, "// handle request"), i(0, "data: 'response'") })),

  -- React useState
  s("us", fmt([[
const [{}, set{}] = useState<{}>({})
]], { i(1, "state"), i(1), i(2, "string"), i(0, "''") })),

  -- React useEffect
  s("ue", fmt([[
useEffect(() => {{
  {}
}}, [{}])
]], { i(1, "// effect"), i(0) })),

  -- React Component
  s("rfc", fmt([[
interface {}Props {{
  {}
}}

export default function {}({{ {} }}: {}Props) {{
  return (
    <div>
      {}
    </div>
  )
}}
]], { i(1, "Component"), i(2, "// props"), i(1), i(3), i(1), i(0) })),

  -- Async Function
  s("af", fmt([[
async function {}({}): Promise<{}> {{
  {}
}}
]], { i(1, "functionName"), i(2, "params"), i(3, "void"), i(0) })),

  -- Try Catch
  s("tryc", fmt([[
try {{
  {}
}} catch (error) {{
  console.error('Error:', error)
  {}
}}
]], { i(1, "// code"), i(0) })),

  -- Prisma Query
  s("prisma", fmt([[
const {} = await prisma.{}.{}({{
  {}
}})
]], { i(1, "result"), i(2, "model"), i(3, "findMany"), i(0) })),

  -- TypeScript Interface
  s("int", fmt([[
interface {} {{
  {}
}}
]], { i(1, "Interface"), i(0) })),

  -- TypeScript Type
  s("type", fmt([[
type {} = {{
  {}
}}
]], { i(1, "Type"), i(0) })),

  -- Import React
  s("imr", t("import React from 'react'")),

  -- Import useState
  s("imus", t("import { useState } from 'react'")),

  -- Import useEffect
  s("imue", t("import { useEffect } from 'react'")),
}
