# سرور المنت ایکس و پنل مدیریت
(Element X Server & Admin Panel)

یک راهکار کامل برای راه اندازی سرور Matrix Synapse به همراه پنل مدیریت تحت وب.
طراحی شده برای نصب آسان در محیط‌های **آنلاین** و **آفلاین (بدون اینترنت)**.

[🇺🇸 **English**](./README.md) | [📦 **راهنمای آپدیت**](./UPGRADE.md)

## ویژگی‌ها
*   **Matrix Synapse**: سرور اصلی و استاندارد متریکس (آخرین نسخه).
*   **Synapse Admin**: پنل مدیریت زیبا برای مدیریت کاربران و اتاق‌ها.
*   **Nginx Reverse Proxy**: سرویس‌دهی خودکار به API، پنل مدیریت و صفحه ثبت‌نام.
*   **SSL/HTTPS**: یکپارچه‌سازی Certbot برای دریافت گواهی امنیتی رایگان.
*   **صفحه ثبت‌نام**: صفحه اختصاصی و دوزبانه در مسیر `/register` برای ثبت‌نام کاربران.
*   **نصب دوگانه**: بسته‌های مجزا برای سرورهای متصل و بدون اینترنت.

---

## ⚡ نصب سریع (دستورات یک‌خطی)

### 🌐 نصب آنلاین
```bash
# دانلود و نصب (نیاز به اینترنت روی سرور)
cd /tmp && curl -fsSL https://github.com/aliqajarian/ElementX/archive/refs/heads/main.tar.gz | tar -xz && cd ElementX-main/release/online && sudo ./install_server.sh
```

### 🔌 نصب آفلاین
```bash
# مرحله ۱: روی کامپیوتر با اینترنت (ویندوز)
curl -fsSL https://github.com/aliqajarian/ElementX/archive/refs/heads/main.tar.gz -o ElementX.tar.gz
tar -xzf ElementX.tar.gz
cd ElementX-main/release/offline
prepare_assets.bat

# مرحله ۲: انتقال پوشه offline/ به سرور، سپس:
sudo ./install_server.sh
```

### 🗂️ نصب Legacy
```bash
# برای نصب‌های موجود یا تنظیمات سفارشی
cd /tmp && curl -fsSL https://github.com/aliqajarian/ElementX/archive/refs/heads/main.tar.gz | tar -xz && cd ElementX-main/release/legacy && sudo ./install_server.sh
```

---

## 📂 روش‌های نصب

### ۱. 🌐 نصب آنلاین (Online)
اگر سرور شما به اینترنت دسترسی دارد از این روش استفاده کنید.
*   **مسیر**: [`online/`](./online)
*   **روش اجرا**:
    ۱. پوشه `online` را به سرور منتقل کنید.
    ۲. دستور `sudo ./install_server.sh` را اجرا کنید.
    ۳. مشخصات دامین و نام کاربری مدیر را وارد کنید.
    ۴. اسکریپت به صورت خودکار فایل‌ها و ایمیج‌های داکر را دانلود می‌کند.

### ۲. 🔌 نصب آفلاین (Offline)
اگر سرور شما به اینترنت دسترسی ندارد (شبکه داخلی/Air-gapped).
*   **مسیر**: [`offline/`](./offline)
*   **پیش‌نیاز**: یک کامپیوتر متصل به اینترنت برای دانلود اولیه فایل‌ها.
*   **روش اجرا**:
    ۱. **روی کامپیوتر**: فایل `prepare_assets.bat` (ویندوز) یا `prepare_assets.sh` (لینوکس) را اجرا کنید. این کار پوشه `assets` را می‌سازد.
    ۲. **انتقال**: کل پوشه `offline` (شامل پوشه `assets` ایجاد شده) را با USB یا شبکه به سرور منتقل کنید.
    ۳. **روی سرور**: دستور `sudo ./install_server.sh` را اجرا کنید.

## ⚙️ تنظیمات
سرور به صورت پیش‌فرض روی پورت‌های استاندارد (۸۰ و ۴۴۳ در صورت فعال‌سازی SSL) اجرا می‌شود.
*   **صفحه ثبت‌نام**: `http://<domain>/register` (ثبت‌نام و لینک‌های دانلود)
*   **پنل مدیریت**: `http://<domain>/admin` (مدیریت سرور)
*   **آدرس متریکس**: `http://<domain>/` (اتصال مستقیم به Synapse)
*   **فایل تنظیمات**: `data/homeserver.yaml`

## 🛠️ مدیریت سرور
با استفاده از اسکریپت `manage.sh` می‌توانید کارهای زیر را انجام دهید:
۱. **ساخت کاربر**: ثبت‌نام دستی کاربران جدید.
۲. **تغییر وضعیت ثبت‌نام**: فعال یا غیرفعال کردن ثبت‌نام عمومی (تغییرات به صورت خودکار در صفحه `/register` اعمال می‌شود).
۳. **مشاهده لاگ**: مشاهده وضعیت لحظه‌ای سرور.
۴. **راه‌اندازی مجدد**: ریستارت سریع سرویس‌ها.

---

## 🔄 آپدیت و انتقال

### آپدیت نسخه (نصب موجود)

اگر این بسته را نصب کرده‌اید و می‌خواهید Synapse را به‌روزرسانی کنید:

```bash
# به مسیر نصب بروید
cd /path/to/your/installation

# دانلود آخرین نسخه Synapse
docker-compose pull synapse

# راه‌اندازی مجدد با نسخه جدید
docker-compose down
docker-compose up -d

# بررسی نسخه
docker-compose exec synapse /start.py --version
```

### انتقال (از نصب قدیمی)

اگر سرور Synapse قدیمی دارید و می‌خواهید به این بسته منتقل شوید:

#### پیش‌نیازها
- داده‌های سرور موجود (`homeserver.yaml`, `homeserver.db`, `media_store`, `signing.key`)
- دسترسی root/sudo به سرور

#### مراحل انتقال

**۱. پشتیبان‌گیری از نصب فعلی**
```bash
# توقف سرور فعلی
sudo systemctl stop matrix-synapse
# یا: docker-compose down

# ایجاد پشتیبان کامل
sudo tar -czf synapse-backup-$(date +%Y%m%d).tar.gz /path/to/current/synapse
```

**۲. آماده‌سازی نصب جدید**
```bash
# انتقال پوشه release به سرور
# به پوشه online/ یا offline/ بروید
cd release/online  # یا release/offline
```

**۳. کپی کردن داده‌ها**
```bash
# ایجاد پوشه data
mkdir -p data

# کپی فایل‌های موجود
cp /path/to/old/homeserver.yaml data/homeserver.yaml
cp /path/to/old/homeserver.db data/homeserver.db  # در صورت استفاده از SQLite
cp /path/to/old/signing.key data/signing.key
cp -r /path/to/old/media_store data/media_store
```

**۴. اجرای نصب**
```bash
chmod +x install_server.sh
sudo ./install_server.sh
```

اسکریپت به صورت خودکار:
- ✅ Docker را نصب می‌کند (در صورت عدم وجود)
- ✅ میرورهای ایرانی را پیکربندی می‌کند
- ✅ Nginx reverse proxy را راه‌اندازی می‌کند
- ✅ پنل مدیریت Synapse را مستقر می‌کند
- ✅ homeserver.yaml را برای سازگاری با proxy به‌روز می‌کند
- ✅ تمام سرویس‌ها را راه‌اندازی می‌کند

**۵. بررسی انتقال**
```bash
# بررسی سرویس‌ها
docker-compose ps

# تست Matrix API
curl http://localhost/_matrix/client/versions

# دسترسی به پنل مدیریت
# مرورگر: http://YOUR_SERVER_IP/admin
```

### نکات مهم

**سازگاری دیتابیس**
- **SQLite**: کپی مستقیم کار می‌کند
- **PostgreSQL**: اطمینان حاصل کنید جزئیات اتصال در `homeserver.yaml` صحیح است

**تغییرات پورت**
- نصب قدیمی: پورت ۸۰۰۸
- نصب جدید: پورت ۸۰ (Nginx proxy)
- قوانین فایروال را به‌روز کنید

**بازگشت به حالت قبل (در صورت نیاز)**
```bash
docker-compose down
sudo tar -xzf synapse-backup-YYYYMMDD.tar.gz -C /
sudo systemctl start matrix-synapse
```

برای دستورالعمل‌های کامل آپدیت، [UPGRADE.md](./UPGRADE.md) را مطالعه کنید.

---
