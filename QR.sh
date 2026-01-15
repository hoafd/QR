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
  "Tệp tin (Upload)": [
    { id: 'FILE_PDF', label: 'PDF', icon: FileText, isUpload: true, accept: '.pdf' },
    { id: 'FILE_IMG', label: 'Hình ảnh', icon: ImageIcon, isUpload: true, accept: 'image/*' },
    { id: 'FILE_AUDIO', label: 'Âm thanh (MP3)', icon: Headphones, isUpload: true, accept: 'audio/*' },
    { id: 'FILE_EXCEL', label: 'Excel', icon: FileSpreadsheet, isUpload: true, accept: '.xlsx,.xls,.csv' },
    { id: 'FILE_DOC', label: 'Word/Doc', icon: FileText, isUpload: true, accept: '.doc,.docx' },
    { id: 'FILE_PPT', label: 'PowerPoint', icon: FileText, isUpload: true, accept: '.ppt,.pptx' },
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

echo -e "${GREEN}>>> Đã xong Phần 1. Hãy yêu cầu Phần 2 để hoàn tất cài đặt.${NC}"

#!/bin/bash
# ==============================================================================
# QR - FD Studio Installer (Part 2/2)
# Phiên bản: 7.0.0 (Sub-Accounts, Role-based Access Control, User Management)
# ==============================================================================

APP_DIR="qr_fd_system"
FRONTEND_DIR="$APP_DIR/frontend"
BACKEND_DIR="$APP_DIR/backend"

# Màu sắc
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}>>> [PHẦN 2] THIẾT LẬP HỆ THỐNG TÀI KHOẢN & PHÂN QUYỀN...${NC}"

# 1. Đọc cấu hình cổng từ Phần 1
if [ -f .qr_port_config ]; then
    USER_PORT=$(cat .qr_port_config)
    echo -e "${YELLOW}>>> Sử dụng cổng đã chọn: $USER_PORT${NC}"
else
    USER_PORT=8000
    echo -e "${YELLOW}>>> Không tìm thấy cấu hình cổng, dùng mặc định: 8000${NC}"
fi

# ==============================================================================
# VIẾT TIẾP FRONTEND (REACT - Admin & Auth Logic)
# ==============================================================================
echo -e "${GREEN}>>> Đang cập nhật giao diện Quản trị & Tài khoản...${NC}"

# Lưu ý: Đây là phần nối tiếp vào file QRFDWeb.jsx
cat << 'REACEOF_PART2' >> "$FRONTEND_DIR/src/QRFDWeb.jsx"

// --- ADMIN & USER MANAGEMENT COMPONENTS ---

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
    if (!formData.username || !formData.password) return alert("Thiếu thông tin");
    const token = localStorage.getItem('token');
    const res = await fetch('/api/admin/users', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': token },
      body: JSON.stringify(formData)
    });
    if (res.ok) {
      alert("Đã thêm thành viên!");
      setFormData({ username: '', password: '', role: 'user' });
      fetchUsers();
    } else {
      const err = await res.json();
      alert(err.detail || "Lỗi khi thêm user");
    }
  };

  const handleDeleteUser = async (id) => {
    if (!confirm("Xóa thành viên này? Họ sẽ không thể đăng nhập nữa.")) return;
    const token = localStorage.getItem('token');
    await fetch(`/api/admin/users/${id}`, { method: 'DELETE', headers: { 'Authorization': token } });
    fetchUsers();
  };

  return (
    <div className="space-y-6">
      <div className="bg-white p-6 rounded-xl shadow-sm border">
        <h3 className="font-bold mb-4 text-brand-600">Thêm tài khoản phụ</h3>
        <form onSubmit={handleAddUser} className="flex flex-col lg:flex-row gap-3 items-end">
          <div className="w-full">
            <label className="block text-xs font-bold text-slate-500 mb-1">Tên đăng nhập</label>
            <input className="w-full p-2 border rounded" value={formData.username} onChange={e=>setFormData({...formData, username:e.target.value})} placeholder="user1"/>
          </div>
          <div className="w-full">
            <label className="block text-xs font-bold text-slate-500 mb-1">Mật khẩu</label>
            <input className="w-full p-2 border rounded" type="password" value={formData.password} onChange={e=>setFormData({...formData, password:e.target.value})} placeholder="******"/>
          </div>
          <div className="w-full lg:w-40">
            <label className="block text-xs font-bold text-slate-500 mb-1">Vai trò</label>
            <select className="w-full p-2 border rounded" value={formData.role} onChange={e=>setFormData({...formData, role:e.target.value})}>
              <option value="user">Nhân viên</option>
              <option value="admin">Quản trị</option>
            </select>
          </div>
          <button className="w-full lg:w-auto px-6 py-2 bg-brand-600 text-white rounded font-bold hover:bg-brand-700 whitespace-nowrap">Thêm</button>
        </form>
      </div>

      <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
        <table className="w-full text-left text-sm">
          <thead className="bg-slate-50 text-slate-500 font-bold uppercase text-xs">
            <tr>
              <th className="p-4">ID</th>
              <th className="p-4">Tên đăng nhập</th>
              <th className="p-4">Vai trò</th>
              <th className="p-4 text-right">Hành động</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {users.map(u => (
              <tr key={u.id} className="hover:bg-slate-50">
                <td className="p-4 text-slate-400">#{u.id}</td>
                <td className="p-4 font-medium">{u.username}</td>
                <td className="p-4"><span className={`px-2 py-1 rounded-full text-xs font-bold ${u.role==='admin'?'bg-purple-100 text-purple-600':'bg-blue-100 text-blue-600'}`}>{u.role}</span></td>
                <td className="p-4 text-right">
                  <button onClick={()=>handleDeleteUser(u.id)} className="text-red-500 hover:underline">Xóa</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

const AdminPanel = ({ onLogout, currentUser }) => {
  const [tab, setTab] = useState('links'); // links | users
  const [links, setLinks] = useState([]);
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({ slug: '', target: '', type: 'URL' });
  const [isEditing, setIsEditing] = useState(null);

  const fetchLinks = async () => {
    const token = localStorage.getItem('token');
    const res = await fetch('/api/admin/links', { headers: { 'Authorization': token } });
    if (res.ok) setLinks(await res.json());
  };

  useEffect(() => { fetchLinks(); }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    const token = localStorage.getItem('token');
    const url = isEditing ? `/api/admin/links/${isEditing}` : '/api/admin/links';
    const method = isEditing ? 'PUT' : 'POST';
    
    try {
      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json', 'Authorization': token },
        body: JSON.stringify(formData)
      });
      if (res.ok) {
        setFormData({ slug: '', target: '', type: 'URL' });
        setIsEditing(null);
        fetchLinks();
      } else {
        const err = await res.json();
        alert(err.detail || 'Lỗi lưu dữ liệu');
      }
    } finally { setLoading(false); }
  };

  const handleDelete = async (id) => {
    if (!confirm('Bạn có chắc muốn xóa? QR này sẽ không hoạt động nữa.')) return;
    const token = localStorage.getItem('token');
    await fetch(`/api/admin/links/${id}`, { method: 'DELETE', headers: { 'Authorization': token } });
    fetchLinks();
  };

  const startEdit = (link) => {
    setFormData({ slug: link.slug, target: link.target, type: link.type });
    setIsEditing(link.id);
  };

  // Hàm download QR tĩnh cho Dynamic Link
  const downloadDynamicQR = (slug) => {
    const qr = qrcode(0, 'M');
    // Link điều hướng
    const redirectUrl = `${window.location.protocol}//${window.location.host}/r/${slug}`;
    qr.addData(redirectUrl);
    qr.make();
    
    const canvas = document.createElement('canvas');
    const size = 1000;
    const mod = size / qr.getModuleCount();
    canvas.width = size; canvas.height = size;
    const ctx = canvas.getContext('2d');
    
    ctx.fillStyle = '#ffffff'; ctx.fillRect(0,0,size,size);
    ctx.fillStyle = '#000000';
    for(let r=0;r<qr.getModuleCount();r++) for(let c=0;c<qr.getModuleCount();c++) {
      if(qr.isDark(r,c)) {
        const x=c*mod, y=r*mod;
        ctx.beginPath(); ctx.roundRect(x,y,mod,mod,mod*0.2); ctx.fill();
      }
    }
    const a = document.createElement('a');
    a.download = `dynamic-qr-${slug}.png`;
    a.href = canvas.toDataURL('image/png');
    a.click();
  };

  return (
    <div className="p-6 bg-slate-50 min-h-screen">
      <div className="max-w-6xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-2xl font-bold text-slate-800 flex items-center gap-2">
              <Settings className="text-brand-600"/> Hệ thống Quản trị
            </h1>
            <p className="text-sm text-slate-500">Xin chào, <span className="font-bold">{currentUser?.username}</span> ({currentUser?.role === 'admin' ? 'Quản trị viên' : 'Nhân viên'})</p>
          </div>
          <button onClick={onLogout} className="text-red-600 font-medium hover:bg-red-50 px-4 py-2 rounded">Đăng xuất</button>
        </div>

        {/* TABS */}
        <div className="flex gap-4 mb-6 border-b border-slate-200">
          <button onClick={() => setTab('links')} className={`pb-2 px-4 font-bold text-sm ${tab==='links'?'text-brand-600 border-b-2 border-brand-600':'text-slate-500'}`}>Quản lý QR (Links)</button>
          {currentUser?.role === 'admin' && (
            <button onClick={() => setTab('users')} className={`pb-2 px-4 font-bold text-sm ${tab==='users'?'text-brand-600 border-b-2 border-brand-600':'text-slate-500'}`}>Thành viên (Users)</button>
          )}
        </div>

        {tab === 'users' ? <UserManagement /> : (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            {/* Link Form */}
            <div className="bg-white p-6 rounded-xl shadow-sm border h-fit">
              <h2 className="font-bold mb-4 flex items-center gap-2 text-brand-700">{isEditing ? 'Sửa Link' : 'Tạo QR Động Mới'}</h2>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-slate-500 mb-1">Mã định danh (Slug)</label>
                  <div className="flex items-center border rounded bg-slate-50 px-2">
                    <span className="text-slate-400 text-xs">/r/</span>
                    <input required className="w-full p-2 bg-transparent outline-none text-sm font-medium" placeholder="khuyen-mai-tet" 
                      value={formData.slug} onChange={e => setFormData({...formData, slug: e.target.value})} 
                      disabled={isEditing} 
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-500 mb-1">Link Đích (Target URL)</label>
                  <input required className="w-full p-2 border rounded" placeholder="https://..." 
                    value={formData.target} onChange={e => setFormData({...formData, target: e.target.value})} 
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-500 mb-1">Ghi chú</label>
                  <input className="w-full p-2 border rounded" placeholder="Chiến dịch Facebook..." 
                    value={formData.type} onChange={e => setFormData({...formData, type: e.target.value})} 
                  />
                </div>
                <div className="flex gap-2 pt-2">
                  {isEditing && <button type="button" onClick={()=>{setIsEditing(null); setFormData({slug:'',target:'',type:'URL'})}} className="flex-1 py-2 border rounded text-slate-600">Hủy</button>}
                  <button type="submit" disabled={loading} className="flex-1 py-2 bg-brand-600 text-white rounded font-bold hover:bg-brand-700">
                    {loading ? 'Đang lưu...' : (isEditing ? 'Cập nhật' : 'Tạo mới')}
                  </button>
                </div>
              </form>
            </div>

            {/* Link List */}
            <div className="lg:col-span-2 bg-white rounded-xl shadow-sm border overflow-hidden">
              <div className="p-4 border-b bg-slate-50 flex justify-between items-center">
                <span className="font-bold text-sm text-slate-600">Danh sách Link của bạn</span>
                <span className="text-xs text-slate-400">Tổng: {links.length}</span>
              </div>
              <div className="divide-y max-h-[70vh] overflow-y-auto">
                {links.map(link => (
                  <div key={link.id} className="p-4 hover:bg-slate-50 flex items-center justify-between group">
                    <div className="overflow-hidden">
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-brand-700">/{link.slug}</span>
                        <span className="text-[10px] px-2 py-0.5 bg-slate-100 rounded-full text-slate-500">{link.type}</span>
                        {currentUser?.role === 'admin' && link.username && (
                          <span className="text-[10px] px-2 py-0.5 bg-purple-100 text-purple-600 rounded-full flex items-center gap-1"><User size={10}/> {link.username}</span>
                        )}
                      </div>
                      <div className="text-xs text-slate-500 truncate mt-1 max-w-md" title={link.target}>Target: {link.target}</div>
                      <div className="text-[10px] text-slate-400 mt-1">Lượt quét: <span className="font-bold text-brand-600">{link.clicks}</span> • Tạo: {new Date(link.created_at * 1000).toLocaleDateString()}</div>
                    </div>
                    <div className="flex gap-2">
                      <button onClick={() => downloadDynamicQR(link.slug)} className="p-2 text-brand-600 hover:bg-brand-50 rounded" title="Tải QR"><Download size={16}/></button>
                      <button onClick={() => startEdit(link)} className="p-2 text-slate-600 hover:bg-slate-100 rounded" title="Sửa"><FileSpreadsheet size={16}/></button>
                      <button onClick={() => handleDelete(link.id)} className="p-2 text-red-600 hover:bg-red-50 rounded" title="Xóa"><Share2 size={16}/></button>
                    </div>
                  </div>
                ))}
                {links.length === 0 && <div className="p-8 text-center text-slate-400">Chưa có link nào. Hãy tạo mới!</div>}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

const QRFDWeb = () => {
  const [view, setView] = useState('generator'); // generator | login | admin
  const [authData, setAuthData] = useState({ username: '', password: '' });
  const [currentUser, setCurrentUser] = useState(null);
  
  // States for Generator
  const [category, setCategory] = useState("Mạng Xã Hội");
  const [type, setType] = useState(QR_GROUPS["Mạng Xã Hội"][0]);
  const [formData, setFormData] = useState({ encryption: 'WPA', bin: BANKS[0].bin, coin: 'bitcoin' });
  const [config, setConfig] = useState({ fgColor: '#000000', bgColor: '#ffffff', style: 'rounded', logo: null, logoSize: 0.25, resolution: 1200, useAutoLogo: true });
  
  const canvasRef = useRef(null);
  const fileInputRef = useRef(null);

  // AUTH CHECK
  const checkAuth = async () => {
    const token = localStorage.getItem('token');
    if (!token) return;
    const res = await fetch('/api/me', { headers: { 'Authorization': token } });
    if (res.ok) {
      const user = await res.json();
      setCurrentUser(user);
    } else {
      localStorage.removeItem('token');
    }
  };

  useEffect(() => { checkAuth(); }, []);

  const handleLogin = async (e) => {
    e.preventDefault();
    const res = await fetch('/api/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(authData)
    });
    const data = await res.json();
    if (data.status === 'success') {
      localStorage.setItem('token', data.token);
      setCurrentUser(data.user);
      setView('admin');
    } else {
      alert(data.message || 'Đăng nhập thất bại');
    }
  };

  // --- LOGIC GENERATOR (GIỮ NGUYÊN) ---
  useEffect(() => {
    if (view !== 'generator' || type.isUpload || type.isBc) return; 
    if (config.useAutoLogo && type.logo) {
      const img = new Image(); img.crossOrigin = "Anonymous";
      if (type.logo.startsWith('data:')) img.src = type.logo;
      else img.src = `https://cdn.simpleicons.org/${type.logo}`;
      img.onload = () => setConfig(p => ({ ...p, logo: img }));
      img.onerror = () => setConfig(p => ({ ...p, logo: null }));
    } else if (config.useAutoLogo) {
      setConfig(p => ({ ...p, logo: null }));
    }
  }, [type, config.useAutoLogo, view]);

  const generateData = () => {
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

  const draw = () => {
    if(!canvasRef.current || view !== 'generator' || type.isBc) return;
    const qr = qrcode(0, 'H'); qr.addData(generateData()); qr.make();
    const count = qr.getModuleCount(); const size = config.resolution; const mod = size/count;
    const ctx = canvasRef.current.getContext('2d');
    canvasRef.current.width = size; canvasRef.current.height = size;
    ctx.fillStyle = config.bgColor; ctx.fillRect(0,0,size,size);
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
      ctx.beginPath(); ctx.arc(cx,cx,(ls/2)+10,0,2*Math.PI); ctx.fill(); 
      ctx.save(); ctx.beginPath(); ctx.arc(cx,cx,ls/2,0,2*Math.PI); ctx.clip(); 
      ctx.drawImage(config.logo,lp,lp,ls,ls); ctx.restore();
    }
  };

  useEffect(() => draw(), [formData, type, config, view]);

  const download = () => {
    const l = document.createElement('a'); l.download = `qr-fd-${type.id}.png`;
    l.href = canvasRef.current.toDataURL('image/png'); l.click();
  };

  // --- RENDER ---
  if (view === 'admin') return <AdminPanel currentUser={currentUser} onLogout={() => { localStorage.removeItem('token'); setCurrentUser(null); setView('login'); }} />;

  if (view === 'login') return (
    <div className="min-h-screen flex items-center justify-center bg-slate-100 p-4">
      <div className="bg-white p-8 rounded-xl shadow-lg w-full max-w-sm">
        <h2 className="text-xl font-bold mb-6 text-center text-brand-700">Đăng nhập Hệ thống</h2>
        <form onSubmit={handleLogin}>
          <div className="mb-4">
            <label className="block text-xs font-bold text-slate-500 mb-1">Tên đăng nhập</label>
            <input className="w-full p-3 border rounded bg-slate-50 focus:bg-white" value={authData.username} onChange={e=>setAuthData({...authData, username:e.target.value})} placeholder="admin"/>
          </div>
          <div className="mb-6">
            <label className="block text-xs font-bold text-slate-500 mb-1">Mật khẩu</label>
            <input type="password" className="w-full p-3 border rounded bg-slate-50 focus:bg-white" value={authData.password} onChange={e=>setAuthData({...authData, password:e.target.value})} placeholder="******"/>
          </div>
          <button className="w-full bg-brand-600 text-white py-3 rounded-lg font-bold hover:bg-brand-700 shadow-md transition-all">Đăng nhập</button>
          <button type="button" onClick={()=>setView('generator')} className="w-full mt-4 text-slate-500 text-sm hover:text-brand-600">← Quay lại trang tạo QR</button>
        </form>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-slate-50 font-sans text-slate-800 flex flex-col lg:flex-row lg:h-screen lg:overflow-hidden">
      <div className="w-full lg:w-64 bg-white border-r border-slate-200 flex flex-col lg:h-full max-h-60 lg:max-h-full shadow-sm z-10">
        <div className="p-4 border-b flex items-center justify-between">
          <div className="flex items-center gap-2 font-bold text-lg"><RefreshCw size={18} className="text-brand-600"/> QR-FD</div>
          <button onClick={() => {
            if (currentUser) setView('admin');
            else setView('login');
          }} className="text-xs bg-brand-50 text-brand-700 px-3 py-1.5 rounded-full font-bold hover:bg-brand-100 transition-colors">
            {currentUser ? `Hi, ${currentUser.username}` : 'Đăng nhập'}
          </button>
        </div>
        <div className="flex-1 overflow-y-auto custom-scrollbar p-2 space-y-1">
          {Object.keys(QR_GROUPS).map(cat => (
            <div key={cat}>
              <button onClick={() => setCategory(cat)} className={`w-full text-left px-3 py-2 text-xs font-bold uppercase ${category===cat ? 'text-brand-600':'text-slate-400'}`}>{cat}</button>
              {category===cat && <div className="ml-2 border-l-2 pl-2 space-y-1">{QR_GROUPS[cat].map(t => (
                <button key={t.id} onClick={() => setType(t)} className={`w-full text-left px-3 py-2 text-sm rounded flex items-center gap-2 ${type.id===t.id ? 'bg-brand-50 text-brand-700 font-medium':'text-slate-600 hover:bg-slate-50'}`}><t.icon size={16}/> {t.label}</button>
              ))}</div>}
            </div>
          ))}
        </div>
      </div>

      <div className="flex-1 flex flex-col lg:flex-row lg:overflow-hidden overflow-y-auto">
        <div className="flex-1 p-6 overflow-y-auto custom-scrollbar">
          <h2 className="text-xl font-bold mb-4 flex items-center gap-2"><type.icon className="text-brand-600"/> {type.label}</h2>
          <div className="bg-white p-6 rounded-xl shadow-sm border mb-6">
            <h3 className="text-xs font-bold text-slate-400 uppercase mb-3">Thông tin</h3>
            {!type.isBc && type.fields.map(f => (
              <div key={f.name} className="mb-4">
                <label className="text-xs font-bold text-slate-500 mb-1 block">{f.label}</label>
                {f.type === 'select' ? (
                  <select className="w-full p-2.5 border rounded-lg bg-white" onChange={e => setFormData({...formData, [f.name]: e.target.value})}>
                    {f.options && f.options.map((o, i) => <option key={i} value={f.values ? f.values[i] : o}>{o}</option>)}
                  </select>
                ) : (
                  <input className="w-full p-2.5 border rounded-lg" type={f.type||'text'} placeholder={f.placeholder} onChange={e => setFormData({...formData, [f.name]: e.target.value})} />
                )}
              </div>
            ))}
            {type.isBc && <div className="p-4 text-center text-slate-500 border rounded bg-slate-50">Chọn loại mã vạch để tạo</div>}
          </div>

          <div className="bg-white p-6 rounded-xl shadow-sm border">
            <h3 className="text-xs font-bold text-slate-400 uppercase mb-3">Giao diện</h3>
            <div className="flex gap-4 mb-4">
              <div><label className="text-xs block mb-1">Màu mã</label><input type="color" value={config.fgColor} onChange={e => setConfig({...config, fgColor:e.target.value})} className="h-8 w-16 cursor-pointer rounded border"/></div>
              <div><label className="text-xs block mb-1">Màu nền</label><input type="color" value={config.bgColor} onChange={e => setConfig({...config, bgColor:e.target.value})} className="h-8 w-16 cursor-pointer rounded border"/></div>
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
        </div>
      </div>
    </div>
  );
};
export default QRFDWeb;
REACEOF_PART2

# ==============================================================================
# PHẦN 2: BACKEND (FASTAPI + SQLITE + AUTH)
# ==============================================================================
echo -e "${GREEN}>>> Đang thiết lập Backend với Users & Permissions...${NC}"

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

# --- DATABASE SETUP ---
def get_db():
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    # Create Users Table
    conn.execute('''CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        role TEXT DEFAULT 'user'
    )''')
    
    # Create Links Table with Owner
    conn.execute('''CREATE TABLE IF NOT EXISTS links (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        slug TEXT UNIQUE,
        target TEXT,
        type TEXT,
        clicks INTEGER DEFAULT 0,
        created_at REAL,
        owner_id INTEGER DEFAULT 1
    )''')
    
    # Check default admin
    cur = conn.execute("SELECT * FROM users WHERE username = 'admin'")
    if not cur.fetchone():
        conn.execute("INSERT INTO users (username, password, role) VALUES ('admin', 'admin123', 'admin')")
    
    conn.commit()
    conn.close()

init_db()

# --- AUTH SYSTEM ---
class LoginReq(BaseModel):
    username: str
    password: str

# Simple token store (In-memory for simplicity)
TOKENS = {} 

@app.post("/api/login")
def login(req: LoginReq):
    conn = get_db()
    user = conn.execute("SELECT * FROM users WHERE username = ?", (req.username,)).fetchone()
    conn.close()
    
    if user and user['password'] == req.password:
        token = secrets.token_hex(16)
        TOKENS[token] = {"id": user['id'], "username": user['username'], "role": user['role']}
        return {"status": "success", "token": token, "user": TOKENS[token]}
    return {"status": "error", "message": "Sai thông tin đăng nhập"}

def get_current_user(authorization: str = Header(None)):
    if not authorization or authorization not in TOKENS:
        raise HTTPException(status_code=401, detail="Unauthorized")
    return TOKENS[authorization]

@app.get("/api/me")
def me(user = Depends(get_current_user)):
    return user

# --- USER MANAGEMENT (ADMIN ONLY) ---
class CreateUserReq(BaseModel):
    username: str
    password: str
    role: str

@app.get("/api/admin/users")
def list_users(user = Depends(get_current_user)):
    if user['role'] != 'admin': raise HTTPException(403, "Forbidden")
    conn = get_db()
    users = conn.execute("SELECT id, username, role FROM users").fetchall()
    conn.close()
    return users

@app.post("/api/admin/users")
def create_user(req: CreateUserReq, user = Depends(get_current_user)):
    if user['role'] != 'admin': raise HTTPException(403, "Forbidden")
    conn = get_db()
    try:
        conn.execute("INSERT INTO users (username, password, role) VALUES (?, ?, ?)", 
                     (req.username, req.password, req.role))
        conn.commit()
        return {"status": "success"}
    except sqlite3.IntegrityError:
        raise HTTPException(400, "Username đã tồn tại")
    finally:
        conn.close()

@app.delete("/api/admin/users/{id}")
def delete_user(id: int, user = Depends(get_current_user)):
    if user['role'] != 'admin': raise HTTPException(403, "Forbidden")
    if id == user['id']: raise HTTPException(400, "Không thể tự xóa chính mình")
    conn = get_db()
    conn.execute("DELETE FROM users WHERE id = ?", (id,))
    conn.commit()
    conn.close()
    return {"status": "success"}

# --- LINK MANAGEMENT (OWNERSHIP) ---
class LinkReq(BaseModel):
    slug: str
    target: str
    type: str

@app.get("/api/admin/links")
def list_links(user = Depends(get_current_user)):
    conn = get_db()
    if user['role'] == 'admin':
        # Admin thấy hết, kèm tên người tạo
        sql = "SELECT links.*, users.username FROM links LEFT JOIN users ON links.owner_id = users.id ORDER BY created_at DESC"
        rows = conn.execute(sql).fetchall()
    else:
        # User chỉ thấy của mình
        rows = conn.execute("SELECT * FROM links WHERE owner_id = ? ORDER BY created_at DESC", (user['id'],)).fetchall()
    conn.close()
    return rows

@app.post("/api/admin/links")
def create_link(link: LinkReq, user = Depends(get_current_user)):
    conn = get_db()
    try:
        conn.execute("INSERT INTO links (slug, target, type, created_at, owner_id) VALUES (?, ?, ?, ?, ?)",
                     (link.slug, link.target, link.type, time.time(), user['id']))
        conn.commit()
        return {"status": "success"}
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Slug đã tồn tại")
    finally:
        conn.close()

@app.put("/api/admin/links/{id}")
def update_link(id: int, link: LinkReq, user = Depends(get_current_user)):
    conn = get_db()
    # Check ownership
    if user['role'] != 'admin':
        check = conn.execute("SELECT id FROM links WHERE id = ? AND owner_id = ?", (id, user['id'])).fetchone()
        if not check:
            conn.close()
            raise HTTPException(403, "Không có quyền sửa link này")
    
    conn.execute("UPDATE links SET target = ?, type = ? WHERE id = ?", (link.target, link.type, id))
    conn.commit()
    conn.close()
    return {"status": "success"}

@app.delete("/api/admin/links/{id}")
def delete_link(id: int, user = Depends(get_current_user)):
    conn = get_db()
    if user['role'] != 'admin':
        conn.execute("DELETE FROM links WHERE id = ? AND owner_id = ?", (id, user['id']))
    else:
        conn.execute("DELETE FROM links WHERE id = ?", (id,))
    conn.commit()
    conn.close()
    return {"status": "success"}

# --- REDIRECT SYSTEM ---
@app.get("/r/{slug}")
def redirect_link(slug: str):
    conn = get_db()
    row = conn.execute("SELECT target FROM links WHERE slug = ?", (slug,)).fetchone()
    if row:
        conn.execute("UPDATE links SET clicks = clicks + 1 WHERE slug = ?", (slug,))
        conn.commit()
        conn.close()
        return RedirectResponse(url=row['target'])
    conn.close()
    return JSONResponse(status_code=404, content={"message": "Link not found"})

# --- UPLOAD & STATIC ---
UPLOAD_DIR = "/app/static/uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@app.post("/api/upload")
async def upload_file(file: UploadFile = File(...)):
    try:
        ext = os.path.splitext(file.filename)[1]
        name = f"{uuid.uuid4()}{ext}"
        path = os.path.join(UPLOAD_DIR, name)
        with open(path, "wb") as buffer: shutil.copyfileobj(file.file, buffer)
        return {"status": "success", "url": f"/assets/uploads/{name}"}
    except Exception as e: return {"status": "error", "message": str(e)}

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
RUN mkdir -p /app/static/assets/uploads && ln -s /app/static/assets/uploads /app/static/uploads 
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
