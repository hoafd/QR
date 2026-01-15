#!/bin/bash
# ==============================================================================
# QR - FD Studio Installer (Part 1/2)
# Phiên bản: 5.0.0 (Ultimate - Split Version)
# ==============================================================================

APP_DIR="qr_fd_system"
FRONTEND_DIR="$APP_DIR/frontend"
BACKEND_DIR="$APP_DIR/backend"

# Màu sắc
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}>>> [PHẦN 1] KHỞI TẠO HỆ THỐNG QR - FD STUDIO...${NC}"

# 1. Kiểm tra Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Lỗi: Docker chưa được cài đặt.${NC}"
    exit 1
fi

# 2. Cấu hình Cổng
# Lưu cổng vào file tạm để Phần 2 đọc được
if [ ! -f .qr_port_config ]; then
    read -p "Nhập cổng chạy server (Mặc định 8000): " USER_PORT
    USER_PORT=${USER_PORT:-8000}
    echo "$USER_PORT" > .qr_port_config
else
    USER_PORT=$(cat .qr_port_config)
fi
echo -e "${YELLOW}>>> Server sẽ chạy trên cổng: $USER_PORT${NC}"

# 3. Update & Dọn dẹp
CONTAINER_NAME="qr-fd-server"
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
    echo " -> Dừng và xóa container cũ..."
    docker stop "$CONTAINER_NAME" > /dev/null 2>&1
    docker rm "$CONTAINER_NAME" > /dev/null 2>&1
fi

# 4. Tạo cấu trúc
rm -rf "$APP_DIR"
mkdir -p "$FRONTEND_DIR/src"
mkdir -p "$BACKEND_DIR/app/static/uploads"

# ==============================================================================
# PHẦN 1: CẤU HÌNH FRONTEND CƠ BẢN
# ==============================================================================
echo -e "${GREEN}>>> Đang tạo cấu hình React...${NC}"

cat <<EOF > "$FRONTEND_DIR/package.json"
{
  "name": "qr-fd-web",
  "version": "5.0.0",
  "type": "module",
  "scripts": { "dev": "vite", "build": "vite build", "preview": "vite preview" },
  "dependencies": { 
    "react": "^18.2.0", 
    "react-dom": "^18.2.0", 
    "lucide-react": "^0.300.0", 
    "qrcode-generator": "^1.4.4", 
    "bwip-js": "^4.2.0" 
  },
  "devDependencies": { "@vitejs/plugin-react": "^4.2.0", "vite": "^5.0.0", "autoprefixer": "^10.4.16", "postcss": "^8.4.31", "tailwindcss": "^3.3.5" }
}
EOF

cat <<EOF > "$FRONTEND_DIR/vite.config.js"
import { defineConfig } from 'vite'; import react from '@vitejs/plugin-react';
export default defineConfig({ plugins: [react()] })
EOF

cat <<EOF > "$FRONTEND_DIR/tailwind.config.js"
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: { extend: { colors: { brand: { 500: '#2563eb', 600: '#1d4ed8', 700: '#1e40af' } } } },
  plugins: [],
}
EOF

cat <<EOF > "$FRONTEND_DIR/postcss.config.js"
export default { plugins: { tailwindcss: {}, autoprefixer: {}, }, }
EOF

cat <<EOF > "$FRONTEND_DIR/index.html"
<!doctype html>
<html lang="vi">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>QR - FD Studio</title>
  </head>
  <body><div id="root"></div><script type="module" src="/src/main.jsx"></script></body>
</html>
EOF

cat <<EOF > "$FRONTEND_DIR/src/index.css"
@tailwind base; @tailwind components; @tailwind utilities;
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 4px; }
EOF

cat <<EOF > "$FRONTEND_DIR/src/main.jsx"
import React from 'react'; import ReactDOM from 'react-dom/client';
import QRFDWeb from './QRFDWeb.jsx'; import './index.css';
ReactDOM.createRoot(document.getElementById('root')).render(<React.StrictMode><QRFDWeb /></React.StrictMode>,)
EOF

# --- BẮT ĐẦU FILE REACT (PHẦN DATA & CONSTANTS) ---
# Chúng ta sẽ ghi đè (>) phần đầu file tại đây.
cat << 'REACEOF_PART1' > "$FRONTEND_DIR/src/QRFDWeb.jsx"
import React, { useState, useEffect, useRef } from 'react';
import { 
  Wifi, Link as LinkIcon, User, Mail, MessageSquare, Type, Download, Upload, 
  Settings, RefreshCw, Facebook, Instagram, Youtube, Twitter, Send, Phone, 
  MapPin, Video, Music, Calendar, Bitcoin, DollarSign, ShoppingBag, FileText,
  Image as ImageIcon, Headphones, Globe, Printer, CreditCard, Wallet, Share2, 
  FileSpreadsheet, File
} from 'lucide-react';
import qrcode from 'qrcode-generator';
import bwipjs from 'bwip-js';

// LOGO DATA (SVG Base64)
const LOGOS = {
  VIETQR: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA0OCA0OCI+PHBhdGggZmlsbD0iIzAwNjhGRiIgZD0iTTQgNGg0MHY0MEg0VjR6Ii8+PHBhdGggZmlsbD0iI0ZGRiIgZD0iTTEwIDEwaDEwdjEwSDEwVjEwem0yIDJ2Nmgydi02aC0yem00IDB2Nmgydi02aC0yem0tNCA4aDZWMTJoLTZ2OHptMTQtOHgxMHYxMEgyMlYxMnptMiAydjZoMnYtNmgtMnptNCAwdjZoMnYtNmgtMnptLTQgOGg2VjEyaC02djh6bS0xNCA2aDEwdjEwSDEwVjI2em0yIDJ2Nmgydi02aC0yem00IDB2Nmgydi02aC0yem0tNCA4aDZWMjhoLTZ2OHptMjAtOHYyaC0ydjJ2Mmgydi0yaDJ2Mmgydi0yaC0ydjJoMnYyaC0ydjJoMnYyaC0ydjJoMnYyaC0ydjJoLTJ2LTJoLTJ2LTJoLTJ2LTJoLTJ2LTJoLTJ2LTJoLTJ2LTJoMnYtMmgydjJ2LTJ6Ii8+PC9zdmc+", 
  MOMO: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA0OCA0OCI+PHBhdGggZmlsbD0iI0E1MDA2NCIgZD0iTTQgNGg0MHY0MEg0VjR6Ii8+PHBhdGggZmlsbD0iI0ZGRiIgZD0iTTM1LjkgMzUuOWMtNC44IDAtOC43LTMuOS04LjctOC43cyTMuOS04LjcgOC43LTguNyA4LjcgMy45IDguNyA4LjctMy45IDguNy04LjcgOC43em0wLTEzLjFjLTIuNCAwLTQuNCAyLTQuNCA0LjRzMiA0LjQgNC40IDQuNCA0LjQtMiA0LjQtNC40LTItNC40LTQuNC00LjR6TTEyLjEgMzUuOWMtNC44IDAtOC43LTMuOS04LjctOC43cyTMuOS04LjcgOC43LTguNyA4LjcgMy45IDguNyA4LjctMy45IDguNy04LjcgOC43em0wLTEzLjFjLTIuNCAwLTQuNCAyLTQuNCA0LjRzMiA0LjQgNC40IDQuNCA0LjQtMiA0LjQtNC40LTItNC40LTQuNC00LjR6Ii8+PC9zdmc+",
  ZALOPAY: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA0OCA0OCI+PHBhdGggZmlsbD0iIzAwNjhGRiIgZD0iTTI0IDRDMTIuOTUgNCA0IDEyLjk1IDQgMjRzOC45NSAyMCAyMCAyMCAyMC04Ljk1IDIwLTIwUzM1LjA1IDQgMjQgNHoiLz48cGF0aCBmaWxsPSIjRkZGIiBkPSJNMjkuNSAxOGgtMTF2MTJoMTFWMTh6Ii8+PC9zdmc+",
  VIETTEL: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA0OCA0OCI+PHBhdGggZmlsbD0iI0VFMDAzMyIgZD0iTTI0IDRDMTIuOTUgNCA0IDEyLjk1IDQgMjRzOC45NSAyMCAyMCAyMCAyMC04Ljk1IDIwLTIwUzM1LjA1IDQgMjQgNHoiLz48cGF0aCBmaWxsPSIjRkZGIiBkPSJNMjAgMTJ2MjRsMTItMTJMMjAgMTJ6Ii8+PC9zdmc+"
};

// HELPER FUNCTIONS
const CRC16 = (s) => { let c=0xFFFF; for(let i=0;i<s.length;i++){ c^=s.charCodeAt(i)<<8; for(let j=0;j<8;j++) c=(c&0x8000)?(c<<1)^0x1021:c<<1; } return (c&0xFFFF).toString(16).toUpperCase().padStart(4,'0'); };
const f = (i,v) => i+v.length.toString().padStart(2,'0')+v;
const genVietQR = ({bin,account,amount,content}) => {
  if(!bin||!account) return "ERROR";
  const p = f('00','00069704')+f('01',bin)+f('02',account);
  const m = f('00','A000000727')+f('01',p)+f('02','QRIBFTTA');
  let q = f('00','01')+f('01','12')+f('38',m)+f('53','704');
  if(amount) q+=f('54',amount); q+=f('58','VN');
  if(content) q+=f('62',f('08',content));
  return q+'6304'+CRC16(q+'6304');
};

const BANKS = [
  {name: 'Vietcombank', bin: '970436'}, {name: 'MBBank', bin: '970422'}, {name: 'Techcombank', bin: '970407'},
  {name: 'ACB', bin: '970416'}, {name: 'VPBank', bin: '970432'}, {name: 'VietinBank', bin: '970415'},
  {name: 'BIDV', bin: '970418'}, {name: 'Agribank', bin: '970405'}, {name: 'TPBank', bin: '970423'},
  {name: 'Sacombank', bin: '970403'}, {name: 'VIB', bin: '970441'}, {name: 'MSB', bin: '970432'}
];

const QR_GROUPS = {
  "Mạng Xã Hội": [
    { id: 'FACEBOOK', label: 'Facebook', icon: Facebook, logo: 'facebook', fields: [{ name: 'url', label: 'Link Profile', placeholder: 'https://facebook.com/...' }] },
    { id: 'ZALO', label: 'Zalo', icon: MessageSquare, logo: 'zalo', fields: [{ name: 'phone', label: 'Số điện thoại', placeholder: '09...' }] },
    { id: 'TIKTOK', label: 'TikTok', icon: Video, logo: 'tiktok', fields: [{ name: 'url', label: 'Link TikTok', placeholder: 'https://tiktok.com/@...' }] },
    { id: 'YOUTUBE', label: 'YouTube', icon: Youtube, logo: 'youtube', fields: [{ name: 'url', label: 'Link Video', placeholder: 'https://youtube.com/...' }] },
    { id: 'INSTAGRAM', label: 'Instagram', icon: Instagram, logo: 'instagram', fields: [{ name: 'url', label: 'Link Instagram', placeholder: 'https://instagram.com/...' }] },
    { id: 'TELEGRAM', label: 'Telegram', icon: Send, logo: 'telegram', fields: [{ name: 'username', label: 'Username', placeholder: 'username' }] },
    { id: 'WHATSAPP', label: 'WhatsApp', icon: Phone, logo: 'whatsapp', fields: [{ name: 'phone', label: 'SĐT (84...)', placeholder: '84...' }] },
    { id: 'TWITTER', label: 'X (Twitter)', icon: Twitter, logo: 'x', fields: [{ name: 'url', label: 'Link Profile', placeholder: 'https://x.com/...' }] },
    { id: 'LINKEDIN', label: 'LinkedIn', icon: User, logo: 'linkedin', fields: [{ name: 'url', label: 'Link Profile', placeholder: 'https://linkedin.com/in/...' }] },
    { id: 'REDDIT', label: 'Reddit', icon: MessageSquare, logo: 'reddit', fields: [{ name: 'url', label: 'Link Reddit', placeholder: 'https://reddit.com/...' }] },
    { id: 'SNAPCHAT', label: 'Snapchat', icon: MessageSquare, logo: 'snapchat', fields: [{ name: 'username', label: 'Username' }] },
  ],
  "Tài chính & Ngân hàng": [
    { id: 'VIETQR', label: 'Ngân hàng (VietQR)', icon: CreditCard, logo: LOGOS.VIETQR, fields: [{ name: 'bin', label: 'Ngân hàng', type: 'select', options: BANKS.map(b=>b.name), values: BANKS.map(b=>b.bin) }, { name: 'account', label: 'Số tài khoản', placeholder: 'STK...' }, { name: 'amount', label: 'Số tiền', placeholder: '50000' }, { name: 'content', label: 'Nội dung', placeholder: 'CK...' }] },
    { id: 'MOMO', label: 'Ví MoMo', icon: Wallet, logo: LOGOS.MOMO, fields: [{ name: 'phone', label: 'SĐT MoMo' }] },
    { id: 'ZALOPAY', label: 'ZaloPay', icon: Wallet, logo: LOGOS.ZALOPAY, fields: [{ name: 'phone', label: 'SĐT/Link ZaloPay' }] },
    { id: 'VIETTEL', label: 'Viettel Money', icon: Wallet, logo: LOGOS.VIETTEL, fields: [{ name: 'phone', label: 'SĐT Viettel Money' }] },
    { id: 'PAYPAL', label: 'PayPal', icon: DollarSign, logo: 'paypal', fields: [{ name: 'username', label: 'Username' }] },
    { id: 'UPI', label: 'UPI Payment', icon: CreditCard, fields: [{ name: 'pa', label: 'VPA ID (address)', placeholder: 'name@bank' }, { name: 'pn', label: 'Payee Name' }, { name: 'am', label: 'Amount' }] },
    { id: 'CRYPTO', label: 'Tiền điện tử', icon: Bitcoin, logo: 'bitcoin', fields: [{ name: 'coin', label: 'Loại coin', type: 'select', options: ['bitcoin', 'ethereum', 'usdt'] }, { name: 'address', label: 'Địa chỉ ví' }] },
    { id: 'VENMO', label: 'Venmo', icon: DollarSign, logo: 'venmo', fields: [{ name: 'username', label: 'Username' }] },
  ],
  "Google & Office": [
    { id: 'GOOGLEMAPS', label: 'Google Maps', icon: MapPin, logo: 'googlemaps', fields: [{ name: 'lat', label: 'Vĩ độ (Lat)', placeholder: '10.7...' }, { name: 'long', label: 'Kinh độ (Long)', placeholder: '106.6...' }] },
    { id: 'GOOGLEFORMS', label: 'Google Forms', icon: FileText, logo: 'googleforms', fields: [{ name: 'url', label: 'Link Form', placeholder: 'https://forms.gle/...' }] },
    { id: 'GOOGLEDOCS', label: 'Google Docs', icon: FileText, logo: 'googledocs', fields: [{ name: 'url', label: 'Link Doc' }] },
    { id: 'GOOGLESHEETS', label: 'Google Sheets', icon: FileSpreadsheet, logo: 'googlesheets', fields: [{ name: 'url', label: 'Link Sheet' }] },
    { id: 'GOOGLEREVIEW', label: 'Google Review', icon: MessageSquare, logo: 'google', fields: [{ name: 'url', label: 'Link Review Place' }] },
    { id: 'OFFICE365', label: 'Office 365', icon: FileText, logo: 'microsoftoffice', fields: [{ name: 'url', label: 'Link Document' }] },
  ],
  "Tiện ích": [
    { id: 'WIFI', label: 'Wi-Fi', icon: Wifi, logo: 'wifi', fields: [{ name: 'ssid', label: 'Tên Wifi' }, { name: 'password', label: 'Mật khẩu', type: 'password' }, { name: 'encryption', label: 'Bảo mật', type: 'select', options: ['WPA', 'WEP', 'nopass'], default: 'WPA' }, { name: 'hidden', label: 'Mạng ẩn', type: 'checkbox' }] },
    { id: 'URL', label: 'Liên kết / URL', icon: LinkIcon, fields: [{ name: 'url', label: 'Website URL' }] },
    { id: 'TEXT', label: 'Văn bản', icon: Type, fields: [{ name: 'text', label: 'Nội dung' }] },
    { id: 'EVENT', label: 'Sự kiện / Lịch', icon: Calendar, fields: [{ name: 'summary', label: 'Tên sự kiện' }, { name: 'start', label: 'Bắt đầu', type: 'datetime-local' }, { name: 'end', label: 'Kết thúc', type: 'datetime-local' }] },
    { id: 'EMAIL', label: 'E-mail', icon: Mail, fields: [{ name: 'email', label: 'Đến' }, { name: 'subject', label: 'Tiêu đề' }, { name: 'body', label: 'Nội dung' }] },
    { id: 'SMS', label: 'SMS', icon: MessageSquare, fields: [{ name: 'phone', label: 'SĐT' }, { name: 'message', label: 'Tin nhắn' }] },
    { id: 'CALL', label: 'Cuộc gọi', icon: Phone, fields: [{ name: 'phone', label: 'SĐT' }] },
    { id: 'FACETIME', label: 'Facetime', icon: Video, logo: 'apple', fields: [{ name: 'phone', label: 'SĐT/Email' }] },
  ],
  "Giải trí & Mua sắm": [
    { id: 'SPOTIFY', label: 'Spotify', icon: Music, logo: 'spotify', fields: [{ name: 'url', label: 'Link Bài hát/Playlist' }] },
    { id: 'APPSTORE', label: 'App Store', icon: ShoppingBag, logo: 'appstore', fields: [{ name: 'url', label: 'Link App Store' }] },
    { id: 'GOOGLEPLAY', label: 'CH Play', icon: ShoppingBag, logo: 'googleplay', fields: [{ name: 'url', label: 'Link Google Play' }] },
    { id: 'AMAZON', label: 'Amazon', icon: ShoppingBag, logo: 'amazon', fields: [{ name: 'url', label: 'Link SP' }] },
    { id: 'ETSY', label: 'Etsy', icon: ShoppingBag, logo: 'etsy', fields: [{ name: 'url', label: 'Link Shop' }] },
  ],
  "Mã vạch & 2D": [
    { id: 'BC_CODE128', label: 'Code 128', icon: Printer, isBc: true, bcid: 'code128', fields: [{ name: 'value', label: 'Giá trị', placeholder: 'CODE128' }] },
    { id: 'BC_EAN13', label: 'EAN-13', icon: Printer, isBc: true, bcid: 'ean13', fields: [{ name: 'value', label: '13 số', placeholder: '893...' }] },
    { id: 'BC_UPCA', label: 'UPC-A', icon: Printer, isBc: true, bcid: 'upca', fields: [{ name: 'value', label: '12 số' }] },
    { id: 'BC_PDF417', label: 'PDF417', icon: Printer, isBc: true, bcid: 'pdf417', fields: [{ name: 'value', label: 'Nội dung' }] },
    { id: 'BC_DATAMATRIX', label: 'Data Matrix', icon: Printer, isBc: true, bcid: 'datamatrix', fields: [{ name: 'value', label: 'Nội dung' }] },
    { id: 'BC_AZTEC', label: 'Aztec', icon: Printer, isBc: true, bcid: 'aztec', fields: [{ name: 'value', label: 'Nội dung' }] },
  ]
};
REACEOF_PART1

cat << 'REACEOF_PART2' >> "$FRONTEND_DIR/src/QRFDWeb.jsx"

// --- COMPONENT QUẢN LÝ USER (ADMIN ONLY) ---
const UserManagement = () => {
  const [users, setUsers] = useState([]);
  const [formData, setFormData] = useState({ username: '', password: '', role: 'user' });

  const fetchUsers = async () => {
    const token = localStorage.getItem('token');
    const res = await fetch('/api/admin/users', { headers: { 'Authorization': token } });
    if (res.ok) setUsers(await res.json());
  };
  useEffect(() => { fetchUsers(); }, []);

  const handleAddUser = async (e) => {
    e.preventDefault();
    const token = localStorage.getItem('token');
    const res = await fetch('/api/admin/users', {
      method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': token },
      body: JSON.stringify(formData)
    });
    if (res.ok) { alert("Đã thêm!"); setFormData({ username: '', password: '', role: 'user' }); fetchUsers(); }
    else alert("Lỗi thêm user");
  };

  const handleDeleteUser = async (id) => {
    if (!confirm("Xóa user này?")) return;
    const token = localStorage.getItem('token');
    await fetch(`/api/admin/users/${id}`, { method: 'DELETE', headers: { 'Authorization': token } });
    fetchUsers();
  };

  return (
    <div className="space-y-6 p-4 bg-white rounded-xl shadow-sm border mt-4">
      <h3 className="font-bold text-brand-600">Quản lý Tài khoản</h3>
      <form onSubmit={handleAddUser} className="flex flex-col lg:flex-row gap-3">
        <input className="border p-2 rounded flex-1" placeholder="Username" value={formData.username} onChange={e=>setFormData({...formData,username:e.target.value})} />
        <input className="border p-2 rounded flex-1" type="password" placeholder="Password" value={formData.password} onChange={e=>setFormData({...formData,password:e.target.value})} />
        <select className="border p-2 rounded" value={formData.role} onChange={e=>setFormData({...formData,role:e.target.value})}><option value="user">User</option><option value="admin">Admin</option></select>
        <button className="bg-brand-600 text-white px-4 py-2 rounded hover:bg-brand-700">Thêm</button>
      </form>
      <div className="divide-y border-t mt-4">
        {users.map(u => (
          <div key={u.id} className="py-2 flex justify-between items-center">
            <span><span className="font-bold">{u.username}</span> <span className="text-xs text-slate-500">({u.role})</span></span>
            <button onClick={()=>handleDeleteUser(u.id)} className="text-red-500 text-xs hover:underline">Xóa</button>
          </div>
        ))}
      </div>
    </div>
  );
};

// --- APP CHÍNH ---
const QRFDWeb = () => {
  const [view, setView] = useState('generator'); 
  const [authData, setAuthData] = useState({ username: '', password: '' });
  const [currentUser, setCurrentUser] = useState(null);
  
  // Generator States
  const [category, setCategory] = useState("Mạng Xã Hội");
  const [type, setType] = useState(QR_GROUPS["Mạng Xã Hội"][0]);
  const [formData, setFormData] = useState({ encryption: 'WPA', bin: BANKS[0].bin, coin: 'bitcoin' });
  const [config, setConfig] = useState({ 
    fgColor: '#000000', bgColor: '#ffffff', style: 'rounded', 
    logo: null, logoSize: 0.25, resolution: 1000, useAutoLogo: true 
  });
  
  // Dynamic QR States
  const [dynamicSlug, setDynamicSlug] = useState('');
  const [isSavingDynamic, setIsSavingDynamic] = useState(false);

  const canvasRef = useRef(null);
  const fileInputRef = useRef(null);

  // AUTH CHECK
  useEffect(() => {
    const token = localStorage.getItem('token');
    if (token) {
      fetch('/api/me', { headers: { 'Authorization': token } })
        .then(r => r.ok ? r.json() : null)
        .then(u => { if(u) setCurrentUser(u); else localStorage.removeItem('token'); });
    }
  }, []);

  const handleLogin = async (e) => {
    e.preventDefault();
    const res = await fetch('/api/login', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(authData)
    });
    const data = await res.json();
    if (data.status === 'success') {
      localStorage.setItem('token', data.token);
      setCurrentUser(data.user);
      setView('generator');
    } else alert('Đăng nhập thất bại');
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    setCurrentUser(null);
    setAuthData({ username: '', password: '' });
    // Nếu đang ở tab QR động (yêu cầu login), quay về tab mặc định
    if (category === 'Nâng cao') {
      setCategory("Mạng Xã Hội");
      setType(QR_GROUPS["Mạng Xã Hội"][0]);
    }
  };

  // AUTO LOGO
  useEffect(() => {
    if (config.useAutoLogo && type.logo && !type.isBc) {
      const img = new Image(); img.crossOrigin = "Anonymous";
      img.src = type.logo.startsWith('data:') ? type.logo : `https://cdn.simpleicons.org/${type.logo}`;
      img.onload = () => setConfig(p => ({ ...p, logo: img }));
      img.onerror = () => setConfig(p => ({ ...p, logo: null }));
    } else if (config.useAutoLogo) {
      setConfig(p => ({ ...p, logo: null }));
    }
  }, [type, config.useAutoLogo]);

  // LOGIC TẠO / CẬP NHẬT QR ĐỘNG
  const handleSaveDynamic = async () => {
    if (!formData.slug || !formData.target) return alert("Vui lòng nhập Mã định danh và Link đích");
    setIsSavingDynamic(true);
    const token = localStorage.getItem('token');
    try {
      const res = await fetch('/api/admin/links', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': token },
        body: JSON.stringify({ slug: formData.slug, target: formData.target, type: 'Dynamic' })
      });
      const data = await res.json();
      if (res.ok) {
        setDynamicSlug(formData.slug); // Trigger vẽ lại QR với link ngắn
        alert("Đã lưu QR động thành công!");
      } else {
        alert(data.detail || "Lỗi lưu QR (Có thể mã slug đã tồn tại)");
      }
    } catch { alert("Lỗi kết nối"); }
    setIsSavingDynamic(false);
  };

  // GENERATE DATA STRING
  const generateData = () => {
    // Nếu là Dynamic QR và đã lưu thành công -> Trả về link ngắn
    if (type.id === 'DYNAMIC') {
        const host = window.location.host;
        const protocol = window.location.protocol;
        // Nếu chưa lưu slug, dùng tạm link đích để preview (hoặc chuỗi rỗng)
        const slugToUse = dynamicSlug || formData.slug || 'demo'; 
        return `${protocol}//${host}/r/${slugToUse}`;
    }

    const d = formData;
    switch(type.id) {
      case 'VIETQR': return genVietQR(d);
      case 'MOMO': return `https://me.momo.vn/${d.phone}`;
      case 'ZALOPAY': return d.phone || 'https://zalopay.vn';
      case 'VIETTEL': return d.phone;
      case 'WIFI': return `WIFI:T:${d.encryption};S:${d.ssid||''};P:${d.password||''};H:${d.hidden?'true':'false'};;`;
      case 'URL': case 'FACEBOOK': case 'TIKTOK': case 'YOUTUBE': case 'INSTAGRAM': return d.url || 'https://google.com';
      case 'ZALO': return `https://zalo.me/${d.phone||''}`;
      case 'TELEGRAM': return `https://t.me/${d.username||''}`;
      case 'TEXT': return d.text||'QR';
      default: return 'QR';
    }
  };

  // DRAW CANVAS
  const draw = () => {
    if(!canvasRef.current || view !== 'generator') return;
    const ctx = canvasRef.current.getContext('2d');
    const size = config.resolution; // Dùng độ phân giải từ config
    
    canvasRef.current.width = size; canvasRef.current.height = size;
    ctx.fillStyle = config.bgColor; ctx.fillRect(0,0,size,size);

    if (type.isBc) {
      try {
        bwipjs.toCanvas(canvasRef.current, {
          bcid: type.bcid, text: formData.value || '123456',
          scale: size/200, height: 20, includetext: true, textxalign: 'center',
          barcolor: config.fgColor.replace('#',''), backgroundcolor: config.bgColor.replace('#','')
        });
      } catch {}
    } else {
      const qr = qrcode(0, 'H'); qr.addData(generateData()); qr.make();
      const count = qr.getModuleCount(); const mod = size/count;
      ctx.fillStyle = config.fgColor;
      
      for(let r=0;r<count;r++) for(let c=0;c<count;c++) if(qr.isDark(r,c)) {
        const x=c*mod, y=r*mod;
        if(config.style==='circle') { ctx.beginPath(); ctx.arc(x+mod/2,y+mod/2,mod/2,0,2*Math.PI); ctx.fill(); }
        else if(config.style==='rounded') { ctx.beginPath(); ctx.roundRect(x,y,mod,mod,mod*0.4); ctx.fill(); }
        else ctx.fillRect(x,y,mod+0.5,mod+0.5);
      }
      
      if(config.logo) {
        const ls = size*config.logoSize; const lp = (size-ls)/2; const cx = size/2;
        ctx.fillStyle = config.bgColor;
        ctx.beginPath(); ctx.arc(cx,cx,(ls/2)+(size*0.02),0,2*Math.PI); ctx.fill(); 
        ctx.save(); ctx.beginPath(); ctx.arc(cx,cx,ls/2,0,2*Math.PI); ctx.clip(); 
        ctx.drawImage(config.logo,lp,lp,ls,ls); ctx.restore();
      }
    }
  };

  useEffect(() => draw(), [formData, type, config, view, dynamicSlug]);

  const download = () => {
    const l = document.createElement('a'); l.download = `qr-fd-${type.id}.png`;
    l.href = canvasRef.current.toDataURL('image/png'); l.click();
  };

  if (view === 'login') return (
    <div className="min-h-screen flex items-center justify-center bg-slate-100 p-4">
      <div className="bg-white p-8 rounded-xl shadow-lg w-full max-w-sm">
        <h2 className="text-xl font-bold mb-6 text-center text-brand-700">Đăng nhập Hệ thống</h2>
        <form onSubmit={handleLogin}>
          <input className="w-full p-3 border rounded bg-slate-50 mb-4" value={authData.username} onChange={e=>setAuthData({...authData, username:e.target.value})} placeholder="Username"/>
          <input type="password" class="w-full p-3 border rounded bg-slate-50 mb-6" value={authData.password} onChange={e=>setAuthData({...authData, password:e.target.value})} placeholder="Password"/>
          <button className="w-full bg-brand-600 text-white py-3 rounded-lg font-bold hover:bg-brand-700">Đăng nhập</button>
          <button type="button" onClick={()=>setView('generator')} className="w-full mt-4 text-slate-500 text-sm hover:text-brand-600">← Quay lại trang tạo</button>
        </form>
      </div>
    </div>
  );

  // --- MENU CẤU HÌNH ---
  // Thêm mục DYNAMIC vào QR_GROUPS chỉ khi đã đăng nhập
  const VISIBLE_GROUPS = { ...QR_GROUPS };
  if (currentUser) {
    VISIBLE_GROUPS["Nâng cao"] = [
      { id: 'DYNAMIC', label: 'QR Động (VIP)', icon: Globe, logo: 'google', fields: [
          { name: 'slug', label: 'Mã định danh (Slug)', placeholder: 'vd: khuyen-mai-1 (Không dấu)' },
          { name: 'target', label: 'Link đích (Đến đâu?)', placeholder: 'https://...' }
      ]}
    ];
  }

  return (
    <div className="min-h-screen bg-slate-50 font-sans text-slate-800 flex flex-col lg:flex-row lg:h-screen lg:overflow-hidden">
      {/* SIDEBAR */}
      <div className="w-full lg:w-64 bg-white border-r border-slate-200 flex flex-col lg:h-full max-h-60 lg:max-h-full shadow-sm z-10">
        <div className="p-4 border-b flex items-center justify-between">
          <div className="flex items-center gap-2 font-bold text-lg"><RefreshCw size={18} className="text-brand-600"/> QR-FD</div>
          {currentUser ? (
            <button onClick={handleLogout} className="text-xs bg-red-50 text-red-600 px-3 py-1 rounded font-bold">Thoát</button>
          ) : (
            <button onClick={() => setView('login')} className="text-xs bg-brand-50 text-brand-700 px-3 py-1 rounded font-bold">Login</button>
          )}
        </div>
        <div className="flex-1 overflow-y-auto custom-scrollbar p-2 space-y-1">
          {Object.keys(VISIBLE_GROUPS).filter(k=>k!=="Tệp tin (Upload)").map(cat => (
            <div key={cat}>
              <button onClick={() => setCategory(cat)} className={`w-full text-left px-3 py-2 text-xs font-bold uppercase ${category===cat ? 'text-brand-600':'text-slate-400'}`}>{cat}</button>
              {category===cat && <div className="ml-2 border-l-2 pl-2 space-y-1">{VISIBLE_GROUPS[cat].map(t => (
                <button key={t.id} onClick={() => {setType(t); setDynamicSlug('');}} className={`w-full text-left px-3 py-2 text-sm rounded flex items-center gap-2 ${type.id===t.id ? 'bg-brand-50 text-brand-700 font-medium':'text-slate-600 hover:bg-slate-50'}`}><t.icon size={16}/> {t.label}</button>
              ))}</div>}
            </div>
          ))}
        </div>
        {currentUser?.role === 'admin' && <div className="p-2 border-t"><button onClick={()=>setView(view==='users'?'generator':'users')} className="w-full bg-slate-100 text-slate-600 py-2 rounded text-xs font-bold">{view==='users'?'< Quay lại':'Quản lý User'}</button></div>}
      </div>

      {/* MAIN CONTENT */}
      {view === 'users' ? (
        <div className="flex-1 p-6 overflow-y-auto"><UserManagement /></div>
      ) : (
        <div className="flex-1 flex flex-col lg:flex-row lg:overflow-hidden overflow-y-auto">
          <div className="flex-1 p-6 overflow-y-auto custom-scrollbar">
            <h2 className="text-xl font-bold mb-4 flex items-center gap-2"><type.icon className="text-brand-600"/> {type.label}</h2>
            
            {/* FORM NHẬP LIỆU */}
            <div className="bg-white p-6 rounded-xl shadow-sm border mb-6">
              <h3 className="text-xs font-bold text-slate-400 uppercase mb-3">Nội dung</h3>
              {!type.isBc && type.fields.map(f => (
                <div key={f.name} className="mb-4">
                  <label className="text-xs font-bold text-slate-500 mb-1 block">{f.label}</label>
                  {f.type === 'select' ? (
                    <select className="w-full p-2.5 border rounded-lg bg-white outline-none focus:ring-2 focus:ring-brand-500" onChange={e => setFormData({...formData, [f.name]: e.target.value})}>
                      {f.options && f.options.map((o, i) => <option key={i} value={f.values ? f.values[i] : o}>{o}</option>)}
                    </select>
                  ) : f.type === 'checkbox' ? (
                    <label className="flex items-center gap-2 cursor-pointer"><input type="checkbox" onChange={e => setFormData({...formData, [f.name]: e.target.checked})}/> <span>Kích hoạt</span></label>
                  ) : f.type === 'datetime-local' ? (
                    <input type="datetime-local" className="w-full p-2.5 border rounded-lg outline-none" onChange={e => setFormData({...formData, [f.name]: e.target.value})} />
                  ) : (
                    <input className="w-full p-2.5 border rounded-lg outline-none focus:ring-2 focus:ring-brand-500" type={f.type||'text'} placeholder={f.placeholder} onChange={e => setFormData({...formData, [f.name]: e.target.value})} />
                  )}
                </div>
              ))}
              
              {/* BUTTON LƯU DYNAMIC QR */}
              {type.id === 'DYNAMIC' && (
                <button onClick={handleSaveDynamic} disabled={isSavingDynamic} className="w-full bg-purple-600 text-white py-3 rounded-lg font-bold hover:bg-purple-700 shadow-md">
                  {isSavingDynamic ? 'Đang lưu...' : 'Lưu & Tạo QR Động'}
                </button>
              )}
              
              {type.isBc && <div className="p-4 text-center text-slate-500 border rounded bg-slate-50">Chọn loại mã vạch để tạo</div>}
            </div>

            {/* FORM GIAO DIỆN & KÍCH THƯỚC */}
            <div className="bg-white p-6 rounded-xl shadow-sm border">
              <h3 className="text-xs font-bold text-slate-400 uppercase mb-3">Giao diện & Kích thước</h3>
              <div className="flex gap-4 mb-4">
                <div><label className="text-xs block mb-1">Màu mã</label><input type="color" value={config.fgColor} onChange={e => setConfig({...config, fgColor:e.target.value})} className="h-8 w-16 cursor-pointer rounded border"/></div>
                <div><label className="text-xs block mb-1">Màu nền</label><input type="color" value={config.bgColor} onChange={e => setConfig({...config, bgColor:e.target.value})} className="h-8 w-16 cursor-pointer rounded border"/></div>
              </div>
              
              {/* SLIDER KÍCH THƯỚC */}
              <div className="mb-4">
                <label className="flex justify-between text-xs font-bold text-slate-500 mb-1">
                  <span>Độ phân giải (Size)</span>
                  <span>{config.resolution}px</span>
                </label>
                <input type="range" min="500" max="4000" step="100" value={config.resolution} 
                  onChange={e=>setConfig({...config, resolution: Number(e.target.value)})} 
                  className="w-full h-2 bg-slate-200 rounded-lg appearance-none cursor-pointer"
                />
              </div>

              {!type.isBc && (
                <>
                  <div className="mb-4"><label className="text-xs block mb-1">Kiểu mắt</label><div className="flex gap-2">{['square','rounded','circle'].map(s=><button key={s} onClick={()=>setConfig({...config,style:s})} className={`px-3 py-1 text-xs border rounded transition-all ${config.style===s?'bg-slate-800 text-white':'bg-white hover:bg-slate-50'}`}>{s}</button>)}</div></div>
                  <div className="flex gap-2 items-center">
                    <button onClick={()=>fileInputRef.current.click()} className="border px-3 py-2 rounded text-xs hover:bg-slate-50">Upload Logo</button>
                    <input type="file" ref={fileInputRef} className="hidden" onChange={e=>{if(e.target.files[0]){const r=new FileReader(); r.onload=ev=>{const i=new Image(); i.onload=()=>setConfig(p=>({...p,logo:i,useAutoLogo:false})); i.src=ev.target.result}; r.readAsDataURL(e.target.files[0])}}}/>
                    <label className="text-xs flex items-center gap-1 cursor-pointer"><input type="checkbox" checked={config.useAutoLogo} onChange={e=>setConfig(p=>({...p,useAutoLogo:e.target.checked}))}/> Auto Logo</label>
                    {config.logo && <button onClick={() => setConfig(p=>({...p,logo:null,useAutoLogo:false}))} className="text-red-500 text-xs px-2 hover:underline">Xóa</button>}
                  </div>
                </>
              )}
            </div>
          </div>

          <div className="w-full lg:w-96 bg-slate-100 border-l p-8 flex flex-col items-center justify-center min-h-[400px]">
            <div className="bg-white p-4 rounded-xl shadow-lg mb-6 w-full max-w-xs aspect-square flex items-center justify-center overflow-hidden">
              {type.isBc ? 
                <Barcode value={formData.value || 'CODE'} format={type.bcid} width={2} height={80}/> : 
                <canvas ref={canvasRef} className="w-full h-full object-contain"/>
              }
            </div>
            <button onClick={download} className="w-full bg-brand-600 text-white py-3 rounded-xl font-bold flex items-center justify-center gap-2 hover:bg-brand-700 shadow-lg shadow-brand-200 transition-all transform active:scale-95"><Download size={18}/> Tải xuống PNG</button>
            <p className="mt-4 text-xs text-slate-400">Dung lượng lớn ({config.resolution}px) thích hợp in ấn.</p>
          </div>
        </div>
      )}
    </div>
  );
};
export default QRFDWeb;
REACEOF_PART2

# ==============================================================================
# PHẦN 2: BACKEND (FASTAPI + SQLITE + AUTH)
# ==============================================================================
echo -e "${GREEN}>>> Đang thiết lập Backend...${NC}"

cat <<EOF > "$BACKEND_DIR/requirements.txt"
fastapi>=0.100.0
uvicorn[standard]>=0.20.0
python-multipart>=0.0.6
opencv-python-headless>=4.8.0
numpy>=1.24.0
pillow>=10.0.0
pyzbar>=0.1.9
qrcode[pil]>=7.4.2
EOF

cat <<EOF > "$BACKEND_DIR/app/main.py"
from fastapi import FastAPI, UploadFile, File, HTTPException, Depends, Header
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, RedirectResponse, JSONResponse
from pydantic import BaseModel
import os, sqlite3, uuid, time, secrets

app = FastAPI(title="QR-FD Server")

DB_PATH = "/app/data/qr.db"
os.makedirs("/app/data", exist_ok=True)

def get_db():
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    conn.execute('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT UNIQUE, password TEXT, role TEXT DEFAULT "user")')
    conn.execute('CREATE TABLE IF NOT EXISTS links (id INTEGER PRIMARY KEY, slug TEXT UNIQUE, target TEXT, type TEXT, clicks INTEGER DEFAULT 0, created_at REAL, owner_id INTEGER DEFAULT 1)')
    if not conn.execute("SELECT * FROM users WHERE username = 'admin'").fetchone():
        conn.execute("INSERT INTO users (username, password, role) VALUES ('admin', 'admin123', 'admin')")
    conn.commit()
    conn.close()

init_db()

TOKENS = {} 
class LoginReq(BaseModel): username: str; password: str
@app.post("/api/login")
def login(req: LoginReq):
    conn = get_db()
    user = conn.execute("SELECT * FROM users WHERE username = ?", (req.username,)).fetchone()
    conn.close()
    if user and user['password'] == req.password:
        token = secrets.token_hex(16)
        TOKENS[token] = {"id": user['id'], "username": user['username'], "role": user['role']}
        return {"status": "success", "token": token, "user": TOKENS[token]}
    return {"status": "error", "message": "Sai thông tin"}

def get_current_user(authorization: str = Header(None)):
    if not authorization or authorization not in TOKENS: raise HTTPException(401, "Unauthorized")
    return TOKENS[authorization]

@app.get("/api/me")
def me(user = Depends(get_current_user)): return user

class CreateUserReq(BaseModel): username: str; password: str; role: str
@app.get("/api/admin/users")
def list_users(user = Depends(get_current_user)):
    if user['role'] != 'admin': raise HTTPException(403)
    conn = get_db(); users = conn.execute("SELECT id, username, role FROM users").fetchall(); conn.close(); return users

@app.post("/api/admin/users")
def create_user(req: CreateUserReq, user = Depends(get_current_user)):
    if user['role'] != 'admin': raise HTTPException(403)
    conn = get_db()
    try: conn.execute("INSERT INTO users (username, password, role) VALUES (?, ?, ?)", (req.username, req.password, req.role)); conn.commit(); return {"status": "success"}
    except: raise HTTPException(400, "Username exists")
    finally: conn.close()

@app.delete("/api/admin/users/{id}")
def delete_user(id: int, user = Depends(get_current_user)):
    if user['role'] != 'admin': raise HTTPException(403); 
    if id == user['id']: raise HTTPException(400);
    conn = get_db(); conn.execute("DELETE FROM users WHERE id = ?", (id,)); conn.commit(); conn.close(); return {"status": "success"}

class LinkReq(BaseModel): slug: str; target: str; type: str
@app.get("/api/admin/links")
def list_links(user = Depends(get_current_user)):
    conn = get_db()
    sql = "SELECT links.*, users.username FROM links LEFT JOIN users ON links.owner_id = users.id ORDER BY created_at DESC" if user['role'] == 'admin' else "SELECT * FROM links WHERE owner_id = ? ORDER BY created_at DESC"
    rows = conn.execute(sql, () if user['role']=='admin' else (user['id'],)).fetchall()
    conn.close(); return rows

@app.post("/api/admin/links")
def create_link(link: LinkReq, user = Depends(get_current_user)):
    conn = get_db()
    try: 
        conn.execute("INSERT INTO links (slug, target, type, created_at, owner_id) VALUES (?, ?, ?, ?, ?)", (link.slug, link.target, link.type, time.time(), user['id']))
        conn.commit()
        return {"status": "success"}
    except: raise HTTPException(400, "Slug exists")
    finally: conn.close()

# FIX REDIRECT LOGIC
@app.get("/r/{slug}")
def redirect_link(slug: str):
    conn = get_db()
    row = conn.execute("SELECT target FROM links WHERE slug = ?", (slug,)).fetchone()
    if row:
        conn.execute("UPDATE links SET clicks = clicks + 1 WHERE slug = ?", (slug,))
        conn.commit()
        conn.close()
        target = row['target']
        # FIX: Tự động thêm https nếu thiếu
        if not target.startswith(('http://', 'https://')):
            target = 'https://' + target
        return RedirectResponse(url=target)
    conn.close()
    return JSONResponse(status_code=404, content={"message": "Link not found"})

app.mount("/assets", StaticFiles(directory="/app/static/assets"), name="assets")
@app.get("/")
async def serve_root(): return FileResponse("/app/static/index.html")
@app.get("/{full_path:path}")
async def serve_react_app(full_path: str):
    p = f"/app/static/{full_path}"
    if os.path.exists(p) and os.path.isfile(p): return FileResponse(p)
    return FileResponse("/app/static/index.html")
EOF

# ==============================================================================
# PHẦN 3: DOCKER BUILD
# ==============================================================================
echo -e "${GREEN}>>> Đang Build Docker Image (Vui lòng đợi 3-5 phút - KHÔNG TẮT)...${NC}"
cat <<EOF > "$APP_DIR/Dockerfile"
FROM node:18-alpine as frontend_builder
WORKDIR /app
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ .
RUN npm run build

FROM python:3.11-slim
RUN apt-get update && apt-get install -y libzbar0 libgl1 libglib2.0-0 sqlite3 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/app ./app
COPY --from=frontend_builder /app/dist ./static
VOLUME /app/data
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

cd "$APP_DIR"
docker build -t qr-fd-system:latest .
docker run -d --name qr-fd-server --restart unless-stopped -p $USER_PORT:8000 -v qr_data:/app/data qr-fd-system:latest

# Xóa file tạm
rm -f .qr_port_config

echo -e "========================================================"
echo -e "${GREEN} XONG RỒI! HỆ THỐNG ĐÃ HOÀN TẤT.${NC}"
echo -e " Truy cập: http://localhost:$USER_PORT"
echo -e " Tài khoản Admin mặc định: user: admin / pass: admin123"
echo -e "========================================================"
