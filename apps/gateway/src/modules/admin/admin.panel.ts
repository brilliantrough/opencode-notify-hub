/**
 * The admin panel: a single self-contained page served at `/admin`. All
 * state lives in the browser (the admin token in sessionStorage); the
 * page is a thin shell over the `/v1/admin/*` JSON API. Kept inline so
 * the gateway image needs no static-file plumbing.
 */
export const ADMIN_PANEL_HTML = `<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Notify 管理后台</title>
<style>
  :root { color-scheme: light dark; }
  * { box-sizing: border-box; }
  body {
    font-family: system-ui, -apple-system, "PingFang SC", "Microsoft YaHei", sans-serif;
    margin: 0; padding: 24px; line-height: 1.5;
    background: #f5f6f8; color: #1c1e21;
  }
  .wrap { max-width: 860px; margin: 0 auto; }
  h1 { font-size: 20px; }
  h2 { font-size: 15px; margin: 0 0 8px; }
  .card {
    background: #fff; border: 1px solid #e1e4e8; border-radius: 10px;
    padding: 16px; margin-bottom: 16px;
  }
  input, textarea, button {
    font: inherit; padding: 8px 10px; border-radius: 8px;
    border: 1px solid #d0d7de;
  }
  input, textarea { width: 100%; background: transparent; color: inherit; }
  textarea { min-height: 84px; resize: vertical; font-family: ui-monospace, monospace; font-size: 13px; }
  button { cursor: pointer; background: #1f6feb; border-color: #1f6feb; color: #fff; }
  button.secondary { background: transparent; color: #1f6feb; }
  button.danger { background: #cf222e; border-color: #cf222e; }
  button:disabled { opacity: .55; cursor: default; }
  .row { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
  .row > input { flex: 1; min-width: 180px; width: auto; }
  .muted { color: #6e7781; font-size: 13px; }
  .error { color: #cf222e; font-size: 14px; min-height: 20px; margin: 6px 0; }
  .ok { color: #1a7f37; }
  table { border-collapse: collapse; width: 100%; font-size: 14px; }
  th, td { text-align: left; padding: 8px 10px; border-bottom: 1px solid #eaeef2; }
  th { color: #6e7781; font-weight: 600; }
  .badge { display: inline-block; padding: 1px 8px; border-radius: 999px; font-size: 12px; }
  .badge.yes { background: #dafbe1; color: #116329; }
  .badge.no { background: #ffebe9; color: #82071e; }
  dialog { border-radius: 12px; border: 1px solid #d0d7de; padding: 20px; max-width: 380px; }
  dialog::backdrop { background: rgba(0,0,0,.4); }
  dialog input { margin: 8px 0 16px; }
  #login-view { max-width: 360px; margin: 12vh auto 0; }
  @media (prefers-color-scheme: dark) {
    body { background: #0d1117; color: #e6edf3; }
    .card { background: #161b22; border-color: #30363d; }
    input, textarea { border-color: #30363d; }
    th { color: #8b949e; }
    td, tr { border-color: #21262d; }
    .muted { color: #8b949e; }
    .badge.yes { background: #12261e; color: #56d364; }
    .badge.no { background: #3d1d20; color: #f85149; }
    button { background: #238636; border-color: #238636; }
    button.secondary { background: transparent; color: #58a6ff; }
  }
</style>
</head>
<body>
<div class="wrap">

  <div id="login-view" class="card">
    <h1>Notify 管理后台</h1>
    <div class="error" id="login-error"></div>
    <div class="row" style="flex-direction:column; align-items:stretch">
      <input id="login-username" placeholder="管理员用户名" autocomplete="username">
      <input id="login-password" type="password" placeholder="密码" autocomplete="current-password">
      <button id="login-btn">登录</button>
    </div>
  </div>

  <div id="main-view" style="display:none">
    <div class="row" style="justify-content:space-between; margin-bottom:16px">
      <h1 style="margin:0">Notify 管理后台</h1>
      <button class="secondary" id="logout-btn">退出登录</button>
    </div>

    <div class="card">
      <h2>概览</h2>
      <div id="stats" class="muted">加载中…</div>
    </div>

    <div class="card">
      <h2>添加用户(绕过白名单,无需邮箱验证)</h2>
      <div class="error" id="create-error"></div>
      <div class="row">
        <input id="create-email" placeholder="邮箱,例如 friend@example.com">
        <input id="create-password" placeholder="初始密码(至少 8 位)" style="flex:0 0 220px">
        <button id="create-btn">添加</button>
      </div>
    </div>

    <div class="card">
      <h2>注册白名单</h2>
      <div class="muted" style="margin-bottom:8px">
        域名后缀(如 nju.edu.cn 允许所有 @nju.edu.cn 邮箱)与精确邮箱,每行一条。白名单为空时关闭自由注册。
      </div>
      <div class="error" id="whitelist-error"></div>
      <div class="row" style="align-items:flex-start">
        <div style="flex:1; min-width:220px">
          <div class="muted">域名后缀</div>
          <textarea id="whitelist-domains" placeholder="nju.edu.cn&#10;smail.nju.edu.cn"></textarea>
        </div>
        <div style="flex:1; min-width:220px">
          <div class="muted">精确邮箱</div>
          <textarea id="whitelist-emails" placeholder="friend@gmail.com"></textarea>
        </div>
      </div>
      <div class="row" style="margin-top:10px">
        <button id="whitelist-save">保存白名单</button>
        <span class="muted" id="whitelist-status"></span>
      </div>
    </div>

    <div class="card">
      <h2>注册用户</h2>
      <div class="error" id="users-error"></div>
      <table>
        <thead>
          <tr><th>邮箱</th><th>邮箱已验证</th><th>注册时间</th><th>操作</th></tr>
        </thead>
        <tbody id="users-body"><tr><td colspan="4" class="muted">加载中…</td></tr></tbody>
      </table>
    </div>

    <div class="card">
      <h2>修改管理员密码</h2>
      <div class="error" id="password-error"></div>
      <div class="row">
        <input id="password-current" type="password" placeholder="当前密码">
        <input id="password-new" type="password" placeholder="新密码(至少 8 位)">
        <button id="password-save">修改密码</button>
      </div>
    </div>
  </div>
</div>

<dialog id="reset-dialog">
  <h2 style="margin-top:0">重置用户密码</h2>
  <div class="muted" id="reset-email"></div>
  <input id="reset-password" placeholder="新密码(至少 8 位)">
  <div class="error" id="reset-error"></div>
  <div class="row" style="justify-content:flex-end">
    <button class="secondary" id="reset-cancel">取消</button>
    <button id="reset-confirm">重置</button>
  </div>
</dialog>

<script>
"use strict";
const $ = (id) => document.getElementById(id);
let adminToken = sessionStorage.getItem("notifyAdminToken") || "";

async function api(method, path, body) {
  const options = { method, headers: {} };
  if (adminToken) options.headers["Authorization"] = "Bearer " + adminToken;
  if (body !== undefined) {
    options.headers["Content-Type"] = "application/json";
    options.body = JSON.stringify(body);
  }
  const response = await fetch(path, options);
  if (response.status === 401 && path !== "/v1/admin/login") {
    showLogin("登录已过期,请重新登录");
    throw new Error("unauthorized");
  }
  const data = response.status === 204 ? null : await response.json().catch(() => null);
  if (!response.ok) {
    const message = data && data.error && data.error.message ? data.error.message : ("HTTP " + response.status);
    throw new Error(message);
  }
  return data;
}

function showLogin(message) {
  adminToken = "";
  sessionStorage.removeItem("notifyAdminToken");
  $("login-view").style.display = "";
  $("main-view").style.display = "none";
  $("login-error").textContent = message || "";
}

function showMain() {
  $("login-view").style.display = "none";
  $("main-view").style.display = "";
  refreshStats();
  refreshUsers();
  refreshWhitelist();
}

$("login-btn").addEventListener("click", async () => {
  const username = $("login-username").value.trim();
  const password = $("login-password").value;
  $("login-error").textContent = "";
  $("login-btn").disabled = true;
  try {
    const data = await api("POST", "/v1/admin/login", { username, password });
    adminToken = data.accessToken;
    sessionStorage.setItem("notifyAdminToken", adminToken);
    showMain();
  } catch (error) {
    $("login-error").textContent = "登录失败:" + error.message;
  } finally {
    $("login-btn").disabled = false;
  }
});
$("login-password").addEventListener("keydown", (event) => {
  if (event.key === "Enter") $("login-btn").click();
});

$("logout-btn").addEventListener("click", () => showLogin());

async function refreshStats() {
  try {
    const data = await api("GET", "/v1/admin/users");
    $("stats").textContent = "注册用户:" + data.total + " 个";
  } catch (error) {
    $("stats").textContent = "加载失败:" + error.message;
  }
}

function formatTime(value) {
  const date = new Date(value);
  return isNaN(date.getTime()) ? value : date.toLocaleString("zh-CN", { hour12: false });
}

async function refreshUsers() {
  const body = $("users-body");
  try {
    const data = await api("GET", "/v1/admin/users");
    if (data.users.length === 0) {
      body.innerHTML = '<tr><td colspan="4" class="muted">暂无注册用户</td></tr>';
      return;
    }
    body.innerHTML = data.users.map((user) =>
      "<tr>" +
      "<td>" + escapeHtml(user.email) + "</td>" +
      '<td><span class="badge ' + (user.verified ? "yes" : "no") + '">' + (user.verified ? "是" : "否") + "</span></td>" +
      "<td>" + escapeHtml(formatTime(user.createdAt)) + "</td>" +
      '<td><button class="secondary" data-reset="' + user.id + '" data-email="' + escapeHtml(user.email) + '">重置密码</button></td>' +
      "</tr>"
    ).join("");
    body.querySelectorAll("[data-reset]").forEach((button) => {
      button.addEventListener("click", () => {
        resetUserId = button.dataset.reset;
        $("reset-email").textContent = button.dataset.email;
        $("reset-password").value = "";
        $("reset-error").textContent = "";
        $("reset-dialog").showModal();
      });
    });
  } catch (error) {
    body.innerHTML = '<tr><td colspan="4" class="muted">加载失败:' + escapeHtml(error.message) + "</td></tr>";
  }
}

let resetUserId = null;

$("reset-cancel").addEventListener("click", () => $("reset-dialog").close());
$("reset-confirm").addEventListener("click", async () => {
  const password = $("reset-password").value;
  $("reset-error").textContent = "";
  if (password.length < 8) {
    $("reset-error").textContent = "密码至少 8 位";
    return;
  }
  try {
    await api("POST", "/v1/admin/users/" + resetUserId + "/reset-password", { password });
    $("reset-dialog").close();
    alert("密码已重置");
  } catch (error) {
    $("reset-error").textContent = error.message;
  }
});

$("create-btn").addEventListener("click", async () => {
  const email = $("create-email").value.trim();
  const password = $("create-password").value;
  $("create-error").textContent = "";
  try {
    await api("POST", "/v1/admin/users", { email, password });
    $("create-email").value = "";
    $("create-password").value = "";
    $("create-error").textContent = "已添加";
    $("create-error").className = "error ok";
    refreshUsers();
    refreshStats();
  } catch (error) {
    $("create-error").className = "error";
    $("create-error").textContent = error.message;
  }
});

function parseLines(value) {
  return value.split(/\\n/).map((line) => line.trim()).filter((line) => line !== "");
}

async function refreshWhitelist() {
  try {
    const data = await api("GET", "/v1/admin/whitelist");
    $("whitelist-domains").value = data.domains.join("\\n");
    $("whitelist-emails").value = data.emails.join("\\n");
  } catch (error) {
    $("whitelist-error").textContent = error.message;
  }
}

$("whitelist-save").addEventListener("click", async () => {
  $("whitelist-error").textContent = "";
  $("whitelist-status").textContent = "保存中…";
  try {
    await api("PUT", "/v1/admin/whitelist", {
      domains: parseLines($("whitelist-domains").value),
      emails: parseLines($("whitelist-emails").value),
    });
    $("whitelist-status").textContent = "已保存";
    refreshWhitelist();
  } catch (error) {
    $("whitelist-status").textContent = "";
    $("whitelist-error").textContent = error.message;
  }
});

$("password-save").addEventListener("click", async () => {
  const currentPassword = $("password-current").value;
  const newPassword = $("password-new").value;
  $("password-error").textContent = "";
  try {
    await api("POST", "/v1/admin/change-password", { currentPassword, newPassword });
    $("password-current").value = "";
    $("password-new").value = "";
    $("password-error").textContent = "密码已修改";
    $("password-error").className = "error ok";
  } catch (error) {
    $("password-error").className = "error";
    $("password-error").textContent = error.message;
  }
});

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (char) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  })[char]);
}

if (adminToken) {
  showMain();
} else {
  showLogin();
}
</script>
</body>
</html>
`;
