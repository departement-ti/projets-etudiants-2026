import { Fragment } from 'react'
import { cn } from '@/lib/utils'

// ─── Inline parser ────────────────────────────────────────────────────────────
// Handles: **bold**, *italic*, `code`, [text](url), bare https:// URLs

const INLINE_RE = /\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`|\[(.+?)\]\((.+?)\)|(https?:\/\/[^\s]+)/g

function parseInline(text: string): React.ReactNode[] {
  const nodes: React.ReactNode[] = []
  let last = 0
  let key = 0

  for (const m of text.matchAll(INLINE_RE)) {
    if (m.index! > last) nodes.push(text.slice(last, m.index))

    const [full, bold, italic, code, linkText, linkHref, url] = m

    if (bold !== undefined) {
      nodes.push(
        <strong key={key++} className="font-semibold text-foreground">
          {bold}
        </strong>,
      )
    } else if (italic !== undefined) {
      nodes.push(<em key={key++}>{italic}</em>)
    } else if (code !== undefined) {
      nodes.push(
        <code key={key++} className="rounded bg-muted px-1 py-0.5 font-mono text-[0.85em]">
          {code}
        </code>,
      )
    } else if (linkText !== undefined && linkHref !== undefined) {
      nodes.push(
        <a
          key={key++}
          href={linkHref}
          target="_blank"
          rel="noopener noreferrer"
          className="text-primary underline-offset-2 hover:underline"
        >
          {linkText}
        </a>,
      )
    } else if (url !== undefined) {
      nodes.push(
        <a
          key={key++}
          href={url}
          target="_blank"
          rel="noopener noreferrer"
          className="break-all text-primary underline-offset-2 hover:underline"
        >
          {url}
        </a>,
      )
    }

    last = m.index! + full.length
  }

  if (last < text.length) nodes.push(text.slice(last))
  return nodes
}

// Renders a run of text preserving single line-breaks as <br>
function renderLines(text: string): React.ReactNode {
  return text.split('\n').map((line, i, arr) => (
    <Fragment key={i}>
      {parseInline(line)}
      {i < arr.length - 1 && <br />}
    </Fragment>
  ))
}

// ─── RichTextRenderer ─────────────────────────────────────────────────────────

export function RichTextRenderer({
  content,
  className,
}: {
  content: string
  className?: string
}) {
  // Tiptap saves HTML; plain-text/markdown lessons use the block parser below
  if (content.trimStart().startsWith('<')) {
    return (
      <div
        className={cn('tiptap-rendered text-sm leading-relaxed', className)}
        dangerouslySetInnerHTML={{ __html: content }}
      />
    )
  }

  const blocks = content.split(/\n{2,}/)

  return (
    <div className={cn('space-y-4 text-sm leading-relaxed text-foreground/90', className)}>
      {blocks.map((block, i) => {
        const raw = block.trim()
        if (!raw) return null

        // Fenced code block
        if (raw.startsWith('```')) {
          const inner = raw.replace(/^```[^\n]*\n?/, '').replace(/\n?```$/, '')
          return (
            <pre key={i} className="overflow-x-auto rounded-lg bg-muted p-4">
              <code className="font-mono text-[0.85em]">{inner}</code>
            </pre>
          )
        }

        // Headings
        if (raw.startsWith('### '))
          return (
            <h3 key={i} className="text-base font-semibold text-foreground">
              {raw.slice(4)}
            </h3>
          )
        if (raw.startsWith('## '))
          return (
            <h2 key={i} className="text-lg font-semibold text-foreground">
              {raw.slice(3)}
            </h2>
          )
        if (raw.startsWith('# '))
          return (
            <h1 key={i} className="text-xl font-bold text-foreground">
              {raw.slice(2)}
            </h1>
          )

        const lines = raw.split('\n')

        // Unordered list
        if (lines[0].match(/^[-*]\s/)) {
          return (
            <ul key={i} className="list-disc space-y-1 pl-5">
              {lines.map((line, li) => (
                <li key={li}>{parseInline(line.replace(/^[-*]\s/, ''))}</li>
              ))}
            </ul>
          )
        }

        // Ordered list
        if (/^\d+\.\s/.test(lines[0])) {
          return (
            <ol key={i} className="list-decimal space-y-1 pl-5">
              {lines.map((line, li) => (
                <li key={li}>{parseInline(line.replace(/^\d+\.\s/, ''))}</li>
              ))}
            </ol>
          )
        }

        // Paragraph
        return <p key={i}>{renderLines(raw)}</p>
      })}
    </div>
  )
}
