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
><img width="1740" height="584" alt="Screenshot 2026-05-07 145818" src="https://github.com/user-attachments/assets/0fb3ae52-b3c5-46af-937a-87ab73e7c6d7" />

> 📸 **СКРІНШОТ 3** — Таблиця `certificate` у pgAdmin  
<img width="705" height="136" alt="image" src="https://github.com/user-attachments/assets/c19daa2b-3436-4d99-8839-52a33e1272de" />

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
<img width="1756" height="595" alt="Screenshot 2026-05-07 145927" src="https://github.com/user-attachments/assets/61bb9da5-f075-4d02-94ae-578388c02eba" />

> 📸 **СКРІНШОТ 5** — Таблиця `course` у pgAdmin з новим полем `ispublished`  
<img width="1568" height="294" alt="image" src="https://github.com/user-attachments/assets/55237e70-e7ce-424e-a079-11d48d2bede8" />

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
<img width="2177" height="813" alt="Screenshot 2026-05-07 150054" src="https://github.com/user-attachments/assets/dfa96513-abd8-40f4-b8e5-7b2cf08d1721" />

> 📸 **СКРІНШОТ 7** — Таблиця `module` у pgAdmin без поля `contenturl`  
<img width="867" height="629" alt="image" src="https://github.com/user-attachments/assets/dcaffd02-08cc-447d-802f-74313cfec6f7" />

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

> 📸 **СКРІНШОТ 9** — Структура папки `prisma/migrations/` у VS Code 
<img width="639" height="470" alt="image" src="https://github.com/user-attachments/assets/419f79f8-dfe8-45d7-9193-fa48be57be05" />

---

## Підсумок змін

| № | Міграція | Тип зміни | Таблиця | Опис |
|---|---|---|---|---|
| 1 | `add_certificate_table` | Додано таблицю | `certificate` | Сертифікат після завершення курсу |
| 2 | `add_course_ispublished` | Додано поле | `course` | Прапорець публікації курсу |
| 3 | `drop_module_contenturl` | Видалено поле | `module` | Видалено URL контенту модуля |
