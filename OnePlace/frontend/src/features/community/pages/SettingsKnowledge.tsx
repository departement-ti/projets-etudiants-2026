import { useRef, useState } from 'react'
import { useParams } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { FileText, Loader2, Plus, RefreshCw, Trash2, Upload } from 'lucide-react'
import { formatDistanceToNow } from 'date-fns'
import { knowledgeApi, type KnowledgeDoc } from '@/api/knowledge'
import { aiApi } from '@/api/ai'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

// ─── DocCard ──────────────────────────────────────────────────────────────────

function DocCard({
  doc,
  communityId,
  onDelete,
  deleting,
}: {
  doc: KnowledgeDoc
  communityId: string
  onDelete: () => void
  deleting: boolean
}) {
  const indexed = doc.embedding.length > 0

  return (
    <div className="flex items-center gap-3 rounded-xl border border-border bg-card px-4 py-3">
      <FileText className="h-4 w-4 shrink-0 text-muted-foreground" />
      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-medium text-foreground">{doc.name}</p>
        <p className="text-xs text-muted-foreground">
          {formatDistanceToNow(new Date(doc.createdAt), { addSuffix: true })}
        </p>
      </div>
      <span
        className={`shrink-0 rounded-full px-2 py-0.5 text-xs font-medium ${
          indexed
            ? 'bg-emerald-500/10 text-emerald-600'
            : 'bg-amber-500/10 text-amber-600'
        }`}
      >
        {indexed ? 'Indexed' : 'Indexing…'}
      </span>
      <button
        onClick={onDelete}
        disabled={deleting}
        className="shrink-0 text-muted-foreground transition-colors hover:text-destructive disabled:opacity-40"
      >
        {deleting ? <Loader2 className="h-4 w-4 animate-spin" /> : <Trash2 className="h-4 w-4" />}
      </button>
    </div>
  )
}

// ─── ReindexCard ─────────────────────────────────────────────────────────────

function ReindexCard({ communityId }: { communityId: string }) {
  const [loading, setLoading] = useState(false)
  const [done, setDone] = useState(false)

  async function handleReindex() {
    setLoading(true)
    try {
      await aiApi.reindex(communityId)
      setDone(true)
      toast.success('Reindexing started — your Q&A bot will be smarter within a few minutes.')
    } catch {
      toast.error('Failed to start reindexing')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="flex items-center justify-between gap-4 rounded-xl border border-border bg-card p-5">
      <div>
        <div className="mb-1 flex items-center gap-2">
          <RefreshCw className="h-4 w-4 text-primary" />
          <p className="text-sm font-semibold text-foreground">Q&A Bot Reindex</p>
        </div>
        <p className="text-xs text-muted-foreground">
          Generate semantic embeddings for all existing posts, lessons, and knowledge docs so the AI Q&A bot can find them by meaning, not just keywords.
          {done && <span className="ml-1 font-medium text-emerald-600">Running in background.</span>}
        </p>
      </div>
      <button
        onClick={handleReindex}
        disabled={loading || done}
        className="shrink-0 rounded-lg bg-primary px-3 py-1.5 text-xs font-semibold text-white hover:opacity-90 disabled:opacity-50"
      >
        {loading ? 'Starting…' : done ? 'Reindexing…' : 'Reindex'}
      </button>
    </div>
  )
}

// ─── SettingsKnowledge ────────────────────────────────────────────────────────

export function SettingsKnowledge() {
  const { id: communityId } = useParams<{ id: string }>()
  const queryClient = useQueryClient()
  const fileInputRef = useRef<HTMLInputElement>(null)

  const [name, setName] = useState('')
  const [content, setContent] = useState('')
  const [deletingId, setDeletingId] = useState<string | null>(null)

  const { data, isLoading } = useQuery({
    queryKey: ['knowledge', communityId],
    queryFn: () => knowledgeApi.list(communityId!),
    enabled: !!communityId,
  })

  const docs = data?.data?.docs ?? []

  const { mutate: createDoc, isPending: creating } = useMutation({
    mutationFn: () => knowledgeApi.create(communityId!, { name: name.trim(), content: content.trim() }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['knowledge', communityId] })
      toast.success('Document added — indexing in background')
      setName('')
      setContent('')
    },
    onError: (err) => toast.error((err as Error).message),
  })

  const { mutate: deleteDoc } = useMutation({
    mutationFn: (docId: string) => knowledgeApi.delete(communityId!, docId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['knowledge', communityId] })
      toast.success('Document removed')
      setDeletingId(null)
    },
    onError: (err) => { toast.error((err as Error).message); setDeletingId(null) },
  })

  function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    e.target.value = ''

    const ext = file.name.split('.').pop()?.toLowerCase()
    if (!['txt', 'md'].includes(ext ?? '')) {
      toast.error('Only .txt and .md files are supported')
      return
    }

    const reader = new FileReader()
    reader.onload = (ev) => {
      const text = ev.target?.result as string
      setContent(text)
      if (!name) setName(file.name.replace(/\.[^.]+$/, ''))
    }
    reader.readAsText(file)
  }

  function handleSubmit() {
    if (!name.trim()) { toast.error('Give this document a name'); return }
    if (!content.trim()) { toast.error('Content is empty'); return }
    createDoc()
  }

  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-lg font-semibold text-foreground">Knowledge Base</h2>
        <p className="mt-1 text-sm text-muted-foreground">
          Upload documents the AI Q&A bot can reference when answering member questions.
        </p>
      </div>

      {/* Add document */}
      <div className="rounded-xl border border-border bg-card p-5 space-y-4">
        <h3 className="text-sm font-semibold text-foreground">Add document</h3>

        <div className="space-y-1.5">
          <Label htmlFor="doc-name">Name</Label>
          <Input
            id="doc-name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="e.g. FAQ, Course syllabus, Rules…"
          />
        </div>

        <div className="space-y-1.5">
          <div className="flex items-center justify-between">
            <Label htmlFor="doc-content">Content</Label>
            <button
              type="button"
              onClick={() => fileInputRef.current?.click()}
              className="flex items-center gap-1.5 text-xs text-primary hover:underline"
            >
              <Upload className="h-3.5 w-3.5" />
              Upload .txt or .md file
            </button>
          </div>
          <textarea
            id="doc-content"
            value={content}
            onChange={(e) => setContent(e.target.value)}
            placeholder="Paste text or upload a file above…"
            rows={6}
            className="w-full resize-y rounded-lg border border-border bg-background px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
          <p className="text-xs text-muted-foreground">{content.length.toLocaleString()} characters</p>
        </div>

        <div className="flex justify-end">
          <Button onClick={handleSubmit} disabled={creating} size="sm">
            {creating ? (
              <><Loader2 className="h-4 w-4 animate-spin" /> Adding…</>
            ) : (
              <><Plus className="h-4 w-4" /> Add document</>
            )}
          </Button>
        </div>

        <input
          ref={fileInputRef}
          type="file"
          accept=".txt,.md"
          className="hidden"
          onChange={handleFileChange}
        />
      </div>

      {/* Reindex */}
      <ReindexCard communityId={communityId!} />

      {/* Document list */}
      <div className="space-y-3">
        <h3 className="text-sm font-semibold text-foreground">
          Documents{docs.length > 0 && <span className="ml-2 text-muted-foreground font-normal">({docs.length})</span>}
        </h3>

        {isLoading ? (
          <div className="flex items-center justify-center py-8">
            <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
          </div>
        ) : docs.length === 0 ? (
          <div className="rounded-xl border border-dashed border-border py-10 text-center text-sm text-muted-foreground">
            No documents yet. Add one above and the bot will start using it.
          </div>
        ) : (
          <div className="space-y-2">
            {docs.map((doc) => (
              <DocCard
                key={doc.id}
                doc={doc}
                communityId={communityId!}
                onDelete={() => { setDeletingId(doc.id); deleteDoc(doc.id) }}
                deleting={deletingId === doc.id}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
