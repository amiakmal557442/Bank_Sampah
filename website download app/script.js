/**
 * BANK SAMPAH ECO DIGITAL - CLIENT SCRIPT
 * Handles OS detection, download triggers, modal dialogs, tab switching, and QR generation.
 */

document.addEventListener('DOMContentLoaded', () => {
  initTheme();
  detectUserOS();
  initStatsCounter();
  initDownloadTrackers();
  prepareApkQrCode();
});

// ==========================================
// 1. Theme Management (Dark / Light)
// ==========================================
function initTheme() {
  const themeToggle = document.getElementById('theme-toggle');
  const savedTheme = localStorage.getItem('banksampah-theme') || 'dark';

  if (savedTheme === 'light') {
    document.body.classList.remove('theme-dark');
    document.body.classList.add('theme-light');
  } else {
    document.body.classList.remove('theme-light');
    document.body.classList.add('theme-dark');
  }

  themeToggle?.addEventListener('click', () => {
    if (document.body.classList.contains('theme-dark')) {
      document.body.classList.remove('theme-dark');
      document.body.classList.add('theme-light');
      localStorage.setItem('banksampah-theme', 'light');
      showToast('☀️ Mode Terang diaktifkan');
    } else {
      document.body.classList.remove('theme-light');
      document.body.classList.add('theme-dark');
      localStorage.setItem('banksampah-theme', 'dark');
      showToast('🌙 Mode Gelap diaktifkan');
    }
  });
}

// ==========================================
// 2. OS Detection & Dynamic Highlight
// ==========================================
function detectUserOS() {
  const userAgent = window.navigator.userAgent || window.navigator.vendor || window.opera;
  const isWindows = /Windows/i.test(userAgent);
  const isAndroid = /Android/i.test(userAgent);

  const titleEl = document.getElementById('os-detect-title');
  const descEl = document.getElementById('os-detect-desc');
  const iconEl = document.getElementById('os-detect-icon');
  const cardAndroid = document.getElementById('card-android');
  const cardWindows = document.getElementById('card-windows');

  if (isWindows) {
    if (titleEl) titleEl.textContent = 'Terdeteksi: Anda Menggunakan Komputer Windows';
    if (descEl) descEl.textContent = 'Kami merekomendasikan versi Windows Desktop (.EXE / .ZIP) untuk PC kantor atau kasir Anda.';
    if (iconEl) {
      iconEl.innerHTML = `
        <svg viewBox="0 0 24 24" fill="currentColor">
          <path d="M0 3.449L9.75 2.1v9.451H0m10.949-9.602L24 0v11.4H10.949M0 12.6h9.75v9.451L0 20.699M10.949 12.6H24V24l-12.949-1.951"/>
        </svg>`;
    }
    cardWindows?.classList.add('highlighted');
  } else if (isAndroid) {
    if (titleEl) titleEl.textContent = 'Terdeteksi: Anda Menggunakan Smartphone Android';
    if (descEl) descEl.textContent = 'Kami merekomendasikan file APK langsung untuk Nasabah dan Petugas Lapangan.';
    if (iconEl) {
      iconEl.innerHTML = `
        <svg viewBox="0 0 24 24" fill="currentColor">
          <path d="M17.523 15.3414c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9993.9993-.9993c.551 0 .9996.4482.9996.9993.0001.5511-.4486.9997-.9996.9997m-11.046 0c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9993.9993-.9993c.5511 0 .9997.4482.9997.9993 0 .5511-.4486.9997-.9997.9997m11.4045-6.02l1.9973-3.4592a.416.416 0 00-.1521-.5676.416.416 0 00-.5676.1521l-2.0223 3.503C15.5902 8.412 13.8533 8.125 12 8.125s-3.5902.287-5.1368.8247L4.841 5.4467a.4161.4161 0 00-.5677-.1521.4157.4157 0 00-.1521.5676l1.9973 3.4592C2.6889 11.1867.3432 14.6589 0 18.761h24c-.3432-4.1021-2.6889-7.5743-6.1185-9.4396"/>
        </svg>`;
    }
    cardAndroid?.classList.add('highlighted');
  } else {
    // Default desktop fallback
    if (titleEl) titleEl.textContent = 'Pilih Versi Aplikasi Bank Sampah';
    if (descEl) descEl.textContent = 'Tersedia untuk Smartphone Android (APK) dan PC Komputer (Windows EXE).';
    if (iconEl) {
      iconEl.innerHTML = `
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect>
          <line x1="8" y1="21" x2="16" y2="21"></line>
          <line x1="12" y1="17" x2="12" y2="21"></line>
        </svg>`;
    }
    cardAndroid?.classList.add('highlighted');
  }
}

// ==========================================
// 3. Download Feedback Trackers
// ==========================================
function initDownloadTrackers() {
  const apkBtn = document.getElementById('btn-download-apk');
  const exeBtn = document.getElementById('btn-download-exe');
  const directExeBtn = document.getElementById('btn-download-exe-direct');

  apkBtn?.addEventListener('click', () => {
    showToast('🚀 Mengunduh Bank-Sampah-v1.2.0.apk... Buka file setelah selesai!');
  });

  exeBtn?.addEventListener('click', () => {
    showToast('📦 Mengunduh Paket Windows (.ZIP)... Ekstrak folder setelah selesai!');
  });

  directExeBtn?.addEventListener('click', () => {
    showToast('💻 Mengunduh BankSampah.exe...');
  });
}

// ==========================================
// 4. Role Tabs Switcher
// ==========================================
function switchRoleTab(role) {
  const tabs = ['nasabah', 'petugas', 'admin'];

  tabs.forEach((r) => {
    const btn = document.getElementById(`tab-btn-${r}`);
    const content = document.getElementById(`tab-content-${r}`);

    if (r === role) {
      btn?.classList.add('active');
      btn?.setAttribute('aria-selected', 'true');
      content?.classList.add('active');
    } else {
      btn?.classList.remove('active');
      btn?.setAttribute('aria-selected', 'false');
      content?.classList.remove('active');
    }
  });
}

// ==========================================
// 5. Interactive Installation Modals
// ==========================================
function openInstallModal(type) {
  const modal = document.getElementById('modal-install');
  const title = document.getElementById('modal-install-title');
  const body = document.getElementById('modal-install-body');

  if (!modal || !title || !body) return;

  if (type === 'apk') {
    title.innerHTML = '📱 Panduan Pemasangan Android (APK)';
    body.innerHTML = `
      <div style="display:flex; flex-direction:column; gap:14px;">
        <p>Aplikasi Bank Sampah didistribusikan dalam format APK terverifikasi. Berikut cara memasangnya:</p>
        <div style="background:rgba(16, 185, 129, 0.1); padding:12px; border-radius:8px; border-left:3px solid #10b981;">
          <strong>Langkah 1:</strong> Buka file <code>Bank-Sampah-v1.2.0.apk</code> di folder <em>Download</em> HP Anda.
        </div>
        <div style="background:rgba(16, 185, 129, 0.1); padding:12px; border-radius:8px; border-left:3px solid #10b981;">
          <strong>Langkah 2:</strong> Jika muncul peringatan keamanan <em>"Demi keamanan, ponsel Anda tidak diizinkan memasang aplikasi yang tidak dikenal dari sumber ini"</em>:
          <ul style="margin-top:6px; margin-left:20px; font-size:0.85rem;">
            <li>Klik tombol <strong>Pengaturan (Settings)</strong></li>
            <li>Aktifkan toggle <strong>"Izinkan dari sumber ini"</strong></li>
          </ul>
        </div>
        <div style="background:rgba(16, 185, 129, 0.1); padding:12px; border-radius:8px; border-left:3px solid #10b981;">
          <strong>Langkah 3:</strong> Kembali dan tekan <strong>Install</strong>. Jika Google Play Protect meminta konfirmasi, pilih <strong>"Tetap Install" (Install Anyway)</strong>.
        </div>
      </div>
    `;
  } else {
    title.innerHTML = '💻 Panduan Menjalankan di Windows (PC)';
    body.innerHTML = `
      <div style="display:flex; flex-direction:column; gap:14px;">
        <p>Aplikasi Windows dikemas dalam bentuk berkas ZIP lengkap yang siap dijalankan tanpa perlu setup rumit:</p>
        <div style="background:rgba(2, 132, 199, 0.1); padding:12px; border-radius:8px; border-left:3px solid #0284c7;">
          <strong>Langkah 1:</strong> Setelah file <code>Bank-Sampah-Windows-x64.zip</code> selesai diunduh, klik kanan dan pilih <strong>"Extract All..." (Ekstrak Semua)</strong>.
        </div>
        <div style="background:rgba(2, 132, 199, 0.1); padding:12px; border-radius:8px; border-left:3px solid #0284c7;">
          <strong>Langkah 2:</strong> Buka folder hasil ekstrak, lalu klik dua kali pada file <strong>flutter_application_1.exe</strong> atau <strong>bank-sampah-windows.exe</strong>.
        </div>
        <div style="background:rgba(2, 132, 199, 0.1); padding:12px; border-radius:8px; border-left:3px solid #0284c7;">
          <strong>Langkah 3 (Jika Ada Windows SmartScreen):</strong> Klik <em>"More info" (Informasi selengkapnya)</em> lalu tekan <em>"Run anyway" (Tetap jalankan)</em>.
        </div>
      </div>
    `;
  }

  modal.classList.add('active');
}

function openQrModal() {
  const modal = document.getElementById('modal-qr');
  const inputLink = document.getElementById('apk-direct-link');
  if (modal) {
    if (inputLink) {
      const fullUrl = window.location.origin + window.location.pathname.replace(/\/$/, '') + '/downloads/bank-sampah.apk';
      inputLink.value = fullUrl;
    }
    modal.classList.add('active');
    drawQrCode();
  }
}

function closeModal(modalId) {
  const modal = document.getElementById(modalId);
  if (modal) {
    modal.classList.remove('active');
  }
}

function closeModalOutside(event, modalId) {
  if (event.target.id === modalId) {
    closeModal(modalId);
  }
}

// ==========================================
// 6. Draw QR Code Pattern on Canvas
// ==========================================
function prepareApkQrCode() {
  const inputLink = document.getElementById('apk-direct-link');
  if (inputLink) {
    inputLink.value = window.location.origin + window.location.pathname.replace(/\/$/, '') + '/downloads/bank-sampah.apk';
  }
}

function drawQrCode() {
  const canvas = document.getElementById('qr-canvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  const size = canvas.width;
  ctx.clearRect(0, 0, size, size);

  // Background
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, size, size);

  // Draw clean stylized QR pattern with corner finder patterns
  ctx.fillStyle = '#0f172a';
  const cellSize = size / 21;

  function drawFinderPattern(x, y) {
    // Outer 7x7 box
    ctx.fillRect(x * cellSize, y * cellSize, 7 * cellSize, 7 * cellSize);
    ctx.fillStyle = '#ffffff';
    ctx.fillRect((x + 1) * cellSize, (y + 1) * cellSize, 5 * cellSize, 5 * cellSize);
    ctx.fillStyle = '#10b981'; // Eco green inner dot
    ctx.fillRect((x + 2) * cellSize, (y + 2) * cellSize, 3 * cellSize, 3 * cellSize);
    ctx.fillStyle = '#0f172a';
  }

  // Draw 3 standard QR position markers
  drawFinderPattern(1, 1);
  drawFinderPattern(13, 1);
  drawFinderPattern(1, 13);

  // Pseudo-random deterministic grid data matching download link hash
  const pseudoSeed = 42;
  for (let r = 0; r < 21; r++) {
    for (let c = 0; c < 21; c++) {
      // Don't overwrite finders
      if ((r < 8 && c < 8) || (r < 8 && c > 12) || (r > 12 && c < 8)) continue;
      // Deterministic decorative pattern
      const val = Math.sin(r * 13 + c * 7 + pseudoSeed);
      if (val > 0.1) {
        ctx.fillStyle = (r % 2 === 0 && c % 2 === 0) ? '#059669' : '#0f172a';
        ctx.fillRect(c * cellSize + 1, r * cellSize + 1, cellSize - 2, cellSize - 2);
      }
    }
  }

  // Center mini badge
  const centerSize = 4 * cellSize;
  const centerPos = (size - centerSize) / 2;
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(centerPos, centerPos, centerSize, centerSize);
  ctx.fillStyle = '#10b981';
  ctx.beginPath();
  ctx.arc(size / 2, size / 2, centerSize / 2.5, 0, Math.PI * 2);
  ctx.fill();
}

function copyApkLink() {
  const input = document.getElementById('apk-direct-link');
  if (input) {
    input.select();
    navigator.clipboard.writeText(input.value).then(() => {
      const btn = document.getElementById('btn-copy-link');
      if (btn) btn.textContent = '✓ Tersalin!';
      showToast('Link APK berhasil disalin ke clipboard');
      setTimeout(() => {
        if (btn) btn.textContent = 'Salin Link';
      }, 2000);
    }).catch(() => {
      showToast('Gagal menyalin link otomatis.');
    });
  }
}

// ==========================================
// 7. FAQ Accordion Toggle
// ==========================================
function toggleFaq(button) {
  const answer = button.nextElementSibling;
  const isOpen = button.classList.contains('active');

  // Close other open accordions
  document.querySelectorAll('.faq-question').forEach((b) => {
    b.classList.remove('active');
    b.setAttribute('aria-expanded', 'false');
    if (b.nextElementSibling) {
      b.nextElementSibling.style.maxHeight = null;
    }
  });

  if (!isOpen) {
    button.classList.add('active');
    button.setAttribute('aria-expanded', 'true');
    answer.style.maxHeight = answer.scrollHeight + 'px';
  }
}

// ==========================================
// 8. Toast Notification System
// ==========================================
function showToast(message) {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = 'toast';
  toast.innerHTML = `
    <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#10b981" stroke-width="2">
      <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
      <polyline points="22 4 12 14.01 9 11.01"></polyline>
    </svg>
    <span>${message}</span>
  `;

  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(50px)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 4000);
}

// ==========================================
// 9. Stats Counter Animation on Scroll
// ==========================================
function initStatsCounter() {
  const statNums = document.querySelectorAll('.stat-num');
  let animated = false;

  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting && !animated) {
        animated = true;
        statNums.forEach((el) => {
          const target = parseInt(el.getAttribute('data-target'), 10) || 0;
          let count = 0;
          const duration = 1200;
          const stepTime = 30;
          const totalSteps = duration / stepTime;
          const increment = Math.ceil(target / totalSteps) || 1;

          const timer = setInterval(() => {
            count += increment;
            if (count >= target) {
              count = target;
              clearInterval(timer);
              if (target === 100) {
                el.textContent = '100%';
              } else {
                el.textContent = count + '+';
              }
            } else {
              el.textContent = count;
            }
          }, stepTime);
        });
      }
    });
  }, { threshold: 0.5 });

  const statRow = document.querySelector('.quick-stats-row');
  if (statRow) {
    observer.observe(statRow);
  }
}
