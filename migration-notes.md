# migration-notes.md
# Лабораторна робота №6 — Міграції схем за допомогою Prisma ORM
**Студентка:** Якубовська О.В., група ІО-45  
**База даних:** `online_courses` (PostgreSQL, localhost:5432)  
**Проект:** `lab6_prisma`

---

## Початковий стан схеми

Після виконання `npx prisma db pull` Prisma зчитала існуючу схему з лабораторної роботи №5 і згенерувала файл `prisma/schema.prisma` з 8 моделями:

| Модель | Таблиця PostgreSQL | Опис |
|---|---|---|
| `User` | `User` | Супертип користувача |
| `student` | `student` | Підтип: студент |
| `instructor` | `instructor` | Підтип: викладач |
| `expertisearea` | `expertisearea` | Довідник спеціалізацій |
| `course` | `course` | Курс |
| `module` | `module` | Модуль курсу |
| `enrollment` | `enrollment` | Зарахування студента |
| `review` | `review` | Відгук на курс |

Початкова міграція `20260507113715_init` зафіксувала цей стан у папці `prisma/migrations/`.

> 📸 **СКРІНШОТ 1** — Вивід терміналу після виконання `npx prisma db pull`  
> <img width="2851" height="814" alt="Screenshot 2026-05-07 143054" src="https://github.com/user-attachments/assets/589c6866-45f6-4173-b33d-7e4e4b6121c2" />

---

## Міграція 1 — Додавання таблиці `certificate`

**Назва міграції:** `20260507115809_add_certificate_table`  
**Команда:** `npx prisma migrate dev --name add-certificate-table`

### Обґрунтування
Студенти, які завершили курс (progress = 100%), мають отримувати сертифікат. Раніше ця інформація ніде не зберігалась. Нова таблиця `certificate` фіксує факт і дату видачі сертифіката.

### Зміни в `schema.prisma`

**До:**
```prisma
model student {
  userid        Int          @id
  academiclevel String       @db.VarChar(50)
  totalpoints   Int          @default(0)
  enrollment    enrollment[]
  review        review[]
  User          User         @relation(fields: [userid], references: [userid], onDelete: Cascade, onUpdate: NoAction)
}

model course {
  courseid     Int          @id @default(autoincrement())
  title        String       @db.VarChar(150)
  description  String?
  price        Decimal      @default(0) @db.Decimal(8, 2)
  instructorid Int
  instructor   instructor   @relation(fields: [instructorid], references: [userid], onUpdate: NoAction)
  enrollment   enrollment[]
  module       module[]
  review       review[]
}
```

**Після:**
```prisma
model student {
  userid        Int           @id
  academiclevel String        @db.VarChar(50)
  totalpoints   Int           @default(0)
  enrollment    enrollment[]
  review        review[]
  certificate   certificate[]
  User          User          @relation(fields: [userid], references: [userid], onDelete: Cascade, onUpdate: NoAction)
}

model course {
  courseid     Int           @id @default(autoincrement())
  title        String        @db.VarChar(150)
  description  String?
  price        Decimal       @default(0) @db.Decimal(8, 2)
  instructorid Int
  instructor   instructor    @relation(fields: [instructorid], references: [userid], onUpdate: NoAction)
  enrollment   enrollment[]
  module       module[]
  review       review[]
  certificate  certificate[]
}

// НОВА МОДЕЛЬ
model certificate {
  certificateid Int      @id @default(autoincrement())
  issuedate     DateTime @default(now()) @db.Date
  studentid     Int
  courseid      Int
  student       student  @relation(fields: [studentid], references: [userid], onDelete: Cascade, onUpdate: NoAction)
  course        course   @relation(fields: [courseid], references: [courseid], onDelete: Cascade, onUpdate: NoAction)

  @@unique([studentid, courseid])
}
```

### Згенерований SQL (`prisma/migrations/20260507115809_add_certificate_table/migration.sql`)
```sql
CREATE TABLE "certificate" (
    "certificateid" SERIAL NOT NULL,
    "issuedate" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "studentid" INTEGER NOT NULL,
    "courseid" INTEGER NOT NULL,
    CONSTRAINT "certificate_pkey" PRIMARY KEY ("certificateid")
);

ALTER TABLE "certificate" ADD CONSTRAINT "certificate_studentid_fkey"
  FOREIGN KEY ("studentid") REFERENCES "student"("userid") ON DELETE CASCADE ON UPDATE NO ACTION;

ALTER TABLE "certificate" ADD CONSTRAINT "certificate_courseid_fkey"
  FOREIGN KEY ("courseid") REFERENCES "course"("courseid") ON DELETE CASCADE ON UPDATE NO ACTION;

CREATE UNIQUE INDEX "certificate_studentid_courseid_key" ON "certificate"("studentid", "courseid");
```

> 📸 **СКРІНШОТ 2** — Вивід терміналу після виконання міграції 1  
> _(зробіть скріншот де видно "Applying migration `20260507115809_add_certificate_table`" та "Your database is now in sync with your schema")_  
> ![migration 1 result](screenshots/02_migration1_certificate.png)

> 📸 **СКРІНШОТ 3** — Таблиця `certificate` у pgAdmin  
> _(у pgAdmin розкрийте Tables → certificate → правою кнопкою → View/Edit Data → All Rows)_  
> ![certificate table pgAdmin](screenshots/03_certificate_table_pgadmin.png)

---

## Міграція 2 — Додавання поля `ispublished` до таблиці `course`

**Назва міграції:** `20260507115916_add_course_ispublished`  
**Команда:** `npx prisma migrate dev --name add-course-ispublished`

### Обґрунтування
Викладачі повинні мати можливість готувати курс перед публікацією. Поле `ispublished` дозволяє відрізняти чернетки від опублікованих курсів. За замовчуванням курс не опублікований (`false`).

### Зміни в `schema.prisma`

**До:**
```prisma
model course {
  courseid     Int          @id @default(autoincrement())
  title        String       @db.VarChar(150)
  description  String?
  price        Decimal      @default(0) @db.Decimal(8, 2)
  instructorid Int
  ...
}
```

**Після:**
```prisma
model course {
  courseid     Int          @id @default(autoincrement())
  title        String       @db.VarChar(150)
  description  String?
  price        Decimal      @default(0) @db.Decimal(8, 2)
  instructorid Int
  ispublished  Boolean      @default(false)   // НОВЕ ПОЛЕ
  ...
}
```

### Згенерований SQL (`prisma/migrations/20260507115916_add_course_ispublished/migration.sql`)
```sql
ALTER TABLE "course" ADD COLUMN "ispublished" BOOLEAN NOT NULL DEFAULT false;
```

> 📸 **СКРІНШОТ 4** — Вивід терміналу після виконання міграції 2  
> _(зробіть скріншот де видно "Applying migration `20260507115916_add_course_ispublished`" та "Your database is now in sync with your schema")_  
> ![migration 2 result](screenshots/04_migration2_ispublished.png)

> 📸 **СКРІНШОТ 5** — Таблиця `course` у pgAdmin з новим полем `ispublished`  
> _(у pgAdmin виконайте `SELECT courseid, title, ispublished FROM course;` і зробіть скріншот результату)_  
> ![course ispublished pgAdmin](screenshots/05_course_ispublished_pgadmin.png)

---

## Міграція 3 — Видалення поля `contenturl` з таблиці `module`

**Назва міграції:** `20260507120049_drop_module_contenturl`  
**Команда:** `npx prisma migrate dev --name drop-module-contenturl`

### Обґрунтування
Поле `contenturl` зберігало посилання на контент модуля у вигляді рядка. В рамках нормалізації було вирішено прибрати це поле — контент модулів зберігатиметься в окремій системі управління медіафайлами, а не в реляційній БД. Видалення усуває надлишкові дані.

### Зміни в `schema.prisma`

**До:**
```prisma
model module {
  moduleid    Int     @id @default(autoincrement())
  courseid    Int
  title       String  @db.VarChar(150)
  ordernumber Int
  contenturl  String? @db.VarChar(255)   // ПОЛЕ ЩО ВИДАЛЯЄТЬСЯ
  course      course  @relation(fields: [courseid], references: [courseid], onDelete: Cascade, onUpdate: NoAction)

  @@unique([courseid, ordernumber])
}
```

**Після:**
```prisma
model module {
  moduleid    Int     @id @default(autoincrement())
  courseid    Int
  title       String  @db.VarChar(150)
  ordernumber Int
  course      course  @relation(fields: [courseid], references: [courseid], onDelete: Cascade, onUpdate: NoAction)

  @@unique([courseid, ordernumber])
}
```

### Згенерований SQL (`prisma/migrations/20260507120049_drop_module_contenturl/migration.sql`)
```sql
ALTER TABLE "module" DROP COLUMN "contenturl";
```

> 📸 **СКРІНШОТ 6** — Вивід терміналу після виконання міграції 3  
> _(зробіть скріншот де видно "Applying migration `20260507120049_drop_module_contenturl`" та "Your database is now in sync with your schema")_  
> ![migration 3 result](screenshots/06_migration3_drop_contenturl.png)

> 📸 **СКРІНШОТ 7** — Таблиця `module` у pgAdmin без поля `contenturl`  
> _(у pgAdmin виконайте `SELECT * FROM module LIMIT 5;` і зробіть скріншот — поля `contenturl` не повинно бути)_  
> ![module table pgAdmin](screenshots/07_module_no_contenturl_pgadmin.png)

---

## Перевірка за допомогою Prisma Client

Для перевірки коректності змін був написаний скрипт `seed.ts`:

```typescript
import * as dotenv from 'dotenv';
dotenv.config();

import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL });
const prisma = new PrismaClient({ adapter });

async function main() {
    // 1. Вставити сертифікат для студента який завершив курс
    const cert = await prisma.certificate.create({
        data: {
            studentid: 19,
            courseid: 21,
            issuedate: new Date('2024-06-15')
        }
    });
    console.log('Створено сертифікат:', cert);

    // 2. Опублікувати курс (оновити ispublished)
    const updatedCourse = await prisma.course.update({
        where: { courseid: 21 },
        data: { ispublished: true }
    });
    console.log('Оновлено курс:', updatedCourse.title, '| ispublished:', updatedCourse.ispublished);

    // 3. Запросити всі сертифікати з даними студента та курсу
    const certificates = await prisma.certificate.findMany({
        include: {
            student: { include: { User: true } },
            course: true
        }
    });
    console.log('\nВсі сертифікати:');
    certificates.forEach(c => {
        console.log(`- ${c.student.User.firstname} ${c.student.User.lastname} | Курс: ${c.course.title} | Дата: ${c.issuedate}`);
    });

    // 4. Запросити опубліковані курси
    const publishedCourses = await prisma.course.findMany({
        where: { ispublished: true }
    });
    console.log('\nОпубліковані курси:');
    publishedCourses.forEach(c => console.log(`- ${c.title}`));
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
```

### Вивід терміналу після запуску `npx tsx seed.ts`

```
◇ injected env (1) from .env
Створено сертифікат: {
  certificateid: 1,
  issuedate: 2024-06-15T00:00:00.000Z,
  studentid: 19,
  courseid: 21
}
Оновлено курс: Python для початківців | ispublished: true
Всі сертифікати:
- Олена Коваль | Курс: Python для початківців | Дата: Sat Jun 15 2024 03:00:00 GMT+0300
Опубліковані курси:
- Python для початківців
```

> 📸 **СКРІНШОТ 8** — Вивід терміналу після запуску `npx tsx seed.ts`  
> _(зробіть скріншот терміналу з повним виводом скрипту — це головний доказ коректної роботи)_  
> ![seed.ts output](screenshots/08_seed_output.png)

---

## Структура папки `prisma/migrations/`

```
prisma/
├── schema.prisma
└── migrations/
    ├── 20260507113715_init/
    │   └── migration.sql
    ├── 20260507115809_add_certificate_table/
    │   └── migration.sql
    ├── 20260507115916_add_course_ispublished/
    │   └── migration.sql
    └── 20260507120049_drop_module_contenturl/
        └── migration.sql
```

> 📸 **СКРІНШОТ 9** — Структура папки `prisma/migrations/` у VS Code або провіднику  
> _(зробіть скріншот лівої панелі VS Code де видно всі 4 підпапки міграцій)_  
> ![migrations folder](screenshots/09_migrations_folder.png)

---

## Підсумок змін

| № | Міграція | Тип зміни | Таблиця | Опис |
|---|---|---|---|---|
| 1 | `add_certificate_table` | Додано таблицю | `certificate` | Сертифікат після завершення курсу |
| 2 | `add_course_ispublished` | Додано поле | `course` | Прапорець публікації курсу |
| 3 | `drop_module_contenturl` | Видалено поле | `module` | Видалено URL контенту модуля |
