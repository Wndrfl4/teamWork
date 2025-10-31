// UI элементы
const titleEl = document.getElementById('title')
const contentEl = document.getElementById('content')
const previewBtn = document.getElementById('previewBtn')
const previewFrame = document.getElementById('preview')
const saveLocalBtn = document.getElementById('saveLocalBtn')
const ownerEl = document.getElementById('owner')
const repoEl = document.getElementById('repo')
const filepathEl = document.getElementById('filepath')
const branchEl = document.getElementById('branch')
const tokenEl = document.getElementById('token')
const commitBtn = document.getElementById('commitBtn')
const logEl = document.getElementById('log')
const commitMsgEl = document.getElementById('commitMsg')
const getShaBtn = document.getElementById('getShaBtn')

// начальное содержимое
contentEl.value = `<section>
  <h2>О нашей команде</h2>
  <p>Здесь вы можете писать новости и обновления проекта.</p>
</section>`

function log(...args){
  logEl.textContent += args.map(a => typeof a === 'object' ? JSON.stringify(a,null,2) : String(a)).join(' ') + '\n'
  logEl.scrollTop = logEl.scrollHeight
}

function buildHtml(){
  return `<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>${escapeHtml(titleEl.value)}</title>
    <style>body{font-family:Arial,Helvetica,sans-serif;padding:28px;line-height:1.5;color:#111}</style>
  </head>
  <body>
    <h1>${escapeHtml(titleEl.value)}</h1>
    ${contentEl.value}
  </body>
</html>`
}

function escapeHtml(s){
  return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;')
}

previewBtn.addEventListener('click', () => {
  const doc = buildHtml()
  previewFrame.srcdoc = doc
})

saveLocalBtn.addEventListener('click', () => {
  const blob = new Blob([buildHtml()], {type: 'text/html'})
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = 'index.html'
  a.click()
  URL.revokeObjectURL(url)
  log('index.html сохранён локально')
})

// --- GitHub commit logic (client-side) ---
// ВНИМАНИЕ: небезопасно хранить/отправлять токен с клиента в публичных условиях.
// Для реального проекта делать commit через свой backend!

async function getFileSha(owner, repo, path, branch, token){
  const url = `https://api.github.com/repos/${owner}/${repo}/contents/${encodeURIComponent(path)}?ref=${encodeURIComponent(branch)}`
  const res = await fetch(url, {
    headers: token ? { Authorization: `token ${token}` } : {}
  })
  if(res.status === 404) return null
  if(!res.ok) throw new Error(`Ошибка получения файла: ${res.status}`)
  const data = await res.json()
  return data.sha
}

function toBase64(str){
  return btoa(unescape(encodeURIComponent(str)))
}

async function putFile(owner, repo, path, branch, token, content, message, sha){
  const url = `https://api.github.com/repos/${owner}/${repo}/contents/${encodeURIComponent(path)}`
  const body = {
    message,
    content: toBase64(content),
    branch
  }
  if(sha) body.sha = sha
  const res = await fetch(url, {
    method: 'PUT',
    headers: {
      Authorization: `token ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(body)
  })
  const data = await res.json()
  if(!res.ok) throw new Error(JSON.stringify(data))
  return data
}

commitBtn.addEventListener('click', async () => {
  log('Начинаем коммит...')
  const owner = ownerEl.value.trim()
  const repo = repoEl.value.trim()
  const path = filepathEl.value.trim() || 'index.html'
  const branch = branchEl.value.trim() || 'main'
  const token = tokenEl.value.trim()
  const message = commitMsgEl.value.trim() || 'Auto update via Team Editor'

  if(!owner || !repo || !token){
    log('Введите owner, repo и token')
    return
  }

  try{
    const html = buildHtml()
    log('Проверяем существующий файл на GitHub...')
    const sha = await getFileSha(owner, repo, path, branch, token)
    if(sha) log('Найден существующий файл, sha:', sha)
    else log('Файл не найден — будет создан новый.')

    log('Отправка запроса на GitHub...')
    const res = await putFile(owner, repo, path, branch, token, html, message, sha)
    log('Успех! Коммит:', res.commit && res.commit.sha)
  }catch(e){
    log('Ошибка:', e.message ? e.message : e)
  }
})

getShaBtn.addEventListener('click', async () => {
  const owner = ownerEl.value.trim()
  const repo = repoEl.value.trim()
  const path = filepathEl.value.trim() || 'index.html'
  const branch = branchEl.value.trim() || 'main'
  const token = tokenEl.value.trim()
  if(!owner || !repo || !token){ log('Введите owner, repo, token'); return }
  try{
    const sha = await getFileSha(owner, repo, path, branch, token)
    log('SHA:', sha)
  }catch(e){ log('Ошибка получения SHA:', e.message) }
})
