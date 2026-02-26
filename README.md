# Element X Server

> Self-hosted Matrix chat server with bilingual registration page, web admin panel, and Iranian mirror support.

[🇮🇷 فارسی](./release/README_FA.md) · [📋 Install Guide](./release/README.md) · [⬆️ Upgrade Guide](./release/UPGRADE.md)

---

## 📦 Project Layout

```
ElementX/
├── README.md               ← You are here (Developer docs)
│
└── release/                ← 👆 EVERYTHING YOUR SERVER NEEDS
    ├── online/             ← For servers with internet access
    ├── offline/            ← For air-gapped servers (no internet)
    ├── legacy/             ← Old scripts (archived)
    ├── landing.html        ← Registration page (EN + FA)
    ├── README.md           ← End-user install guide (English)
    ├── README_FA.md        ← End-user install guide (Persian)
    └── UPGRADE.md          ← Upgrade & migration guide
```

---

## 🚀 For End Users

**Just follow the guide in `release/README.md`:**
```bash
# Online install (1 command)
cd /tmp && curl -fsSL https://github.com/callmedimi/ElementX/archive/refs/heads/main.tar.gz | tar -xz && cd ElementX-main/release/online && sudo ./install_server.sh
```

---

## 🔧 For Developers

Files outside `release/` are development tools only — **don't transfer them to the server.**

| File | Purpose |
|---|---|
| `deploy.bat` | Build the release bundle |
| `verify.bat` | Check bundle completeness |
| `download_admin.bat` | Download Synapse Admin UI |
| `install_server.sh` | Template only |

**Workflow:**
1. Edit templates
2. Run `deploy.bat`
3. Transfer `release/online` or `release/offline` to your server

---

## 🌐 Iranian Mirror Support

Automatically uses fast Iranian mirrors for both Ubuntu packages and Docker images:
- **Ubuntu**: IranServer, ArvanCloud, Pishgaman, Parspack, and more
- **Docker**: `docker.iranserver.com`, `docker.arvancloud.ir`, `hub.hamdocker.ir`

---

*made with ❤️ by dimi*
