---
type: binding-rule
title: Retire, Don't Erase — Laravel binding
description: How to retire a column or table and back up changed or deleted rows in a Laravel migration, so down() brings the data back. Names, comments and up()/down() examples.
---

# Retire, Don't Erase — Laravel binding

This file maps [`../../README.md`](../../README.md) onto Laravel migrations. It adds no rules; it only says what each role is called here and how to write it.

## Names

| Role | Name |
|---|---|
| Retired column | `retired_{column}`, e.g. `retired_delivery_method` |
| Retired table | `retired_{table}`, e.g. `retired_gift_wraps` |
| Backup of one changed table | `migration_backup_{source_table}_{purpose}`, e.g. `migration_backup_orders_status_spelling` |
| Migration that retires | `retire_{column}_on_{table}` / `retire_{table}_table` |

- **One backup table per changed table.** A migration that rewrites three tables creates three backup tables, each typed for its own columns.
- **Keep names within 63 characters.** Postgres truncates longer identifiers silently (MySQL rejects them above 64), so `{purpose}` stays to two or three words.

## Every retired thing and every backup has a comment

The comment names the migration file that created it and says why, so it can be traced back without the migration, and still makes sense if migration files are ever pruned.

```php
$table->comment('Backup made by 2024_01_15_100000_normalize_order_status_spelling: '
    .'original and rewritten status of each order whose status was spelled "canceled". '
    .'Its down() restores from here.');
```

`$table->comment()` sets a table comment, `->comment()` on a column a column comment. Read them back with `\dt+` / `\d+ {table}` in psql, or `obj_description('{table}'::regclass)`. SQLite ignores table comments, which is harmless in a test database.

## Retiring a column

```php
public function up(): void
{
    Schema::table('orders', function (Blueprint $table) {
        $table->renameColumn('delivery_method', 'retired_delivery_method');
    });

    Schema::table('orders', function (Blueprint $table) {
        $table->string('retired_delivery_method')
            ->nullable()
            ->comment('Retired by 2024_01_15_100000_retire_delivery_method_on_orders: every order ships the same way, so nothing reads this. Kept so down() can bring it back.')
            ->change();
    });
}

public function down(): void
{
    Schema::table('orders', function (Blueprint $table) {
        $table->string('retired_delivery_method')
            ->nullable(false)
            ->default('standard')
            ->comment('How the order is shipped: standard or express')
            ->change();
    });

    Schema::table('orders', function (Blueprint $table) {
        $table->renameColumn('retired_delivery_method', 'delivery_method');
    });
}
```

- **Make it nullable.** A retired `NOT NULL` column without a default makes every new insert fail, because no code fills it any more.
- **`->change()` restates the whole column.** Attributes you leave out (default, nullability, comment) are dropped, so `down()` spells out the original definition in full.
- **Remove it from the model** (casts, fillable, accessors) in the same change. Nothing should read a retired column.

Retiring a table is `Schema::rename('gift_wraps', 'retired_gift_wraps')` plus a table comment; `down()` renames it back. Indexes and constraints keep their old names; that is cosmetic.

## Backing up rewritten rows

The backup table has a foreign key to the changed row, then an `original_{column}` and a `rewritten_{column}` per changed column, each the same type as the source column.

```php
return new class extends Migration
{
    private const BACKUP = 'migration_backup_orders_status_spelling';

    public function up(): void
    {
        Schema::create(self::BACKUP, function (Blueprint $table) {
            $table->comment('Backup made by 2024_01_15_100000_normalize_order_status_spelling: '
                .'original and rewritten status of each order whose status was spelled "canceled". '
                .'Its down() restores from here.');
            $table->id()->comment('Primary key');
            $table->foreignId('order_id')->constrained('orders')->comment('Order whose status this row preserves');
            $table->string('original_status')->comment('orders.status before this migration');
            $table->string('rewritten_status')->comment('orders.status as this migration wrote it; down() restores only while it still equals this');
            $table->timestamps();
        });

        // 1. Back up exactly what is about to change.
        DB::statement('INSERT INTO '.self::BACKUP.' (order_id, original_status, rewritten_status, created_at, updated_at)
            SELECT id, status, ?, now(), now() FROM orders WHERE status = ?', ['cancelled', 'canceled']);

        // 2. Change it.
        DB::statement('UPDATE orders SET status = b.rewritten_status
            FROM '.self::BACKUP.' b WHERE b.order_id = orders.id');

        // 3. Verify, so a wrong result rolls the whole migration back.
        $this->assertNoneDiffer(column: 'rewritten_status', message: 'Rewrite did not land on orders');
    }

    public function down(): void
    {
        // Never overwrite later work: refuse if any order has moved on since.
        $this->assertNoneDiffer(column: 'rewritten_status', message: 'Orders changed since this migration ran, not restoring');

        DB::statement('UPDATE orders SET status = b.original_status
            FROM '.self::BACKUP.' b WHERE b.order_id = orders.id');

        Schema::drop(self::BACKUP);
    }

    private function assertNoneDiffer(string $column, string $message): void
    {
        $orderIds = DB::table(self::BACKUP)
            ->join('orders', 'orders.id', '=', self::BACKUP.'.order_id')
            ->whereColumn('orders.status', '<>', self::BACKUP.'.'.$column)
            ->pluck('orders.id');

        if ($orderIds->isNotEmpty()) {
            throw new RuntimeException($message.': '.$orderIds->implode(', '));
        }
    }
};
```

- **All-or-nothing comes from the migration transaction.** Laravel runs each migration in a transaction where the database supports transactional DDL (Postgres does; leave `$withinTransaction` at its default `true`). An exception anywhere undoes the backup table, the rewrite and all. MySQL commits DDL implicitly, so there the backup table survives a failed rewrite; drop it in a `catch` or rerun.
- **Use the query builder or SQL, not models.** Model events would fire on every row (syncs, observers, recalculation), and the model may have changed shape by the time the migration runs elsewhere.
- **The foreign key protects the backup.** While a backup row exists, the changed row cannot be hard-deleted under it.

## Backing up deleted rows

The backup table copies every column of the deleted row (same names and types, without the source's unique constraints and foreign keys) and has no `rewritten_` columns. `up()` copies the rows, then deletes them; `down()` inserts them back and drops the backup table. A row whose id has been reused since cannot come back, so `down()` refuses and names it, the same way as a rewritten row that has moved on.

## Erasing later

Dropping a `retired_` column or table, or a `migration_backup_` table, is its own migration, written when someone has decided it is no longer needed. Its `down()` cannot bring the data back, so it says so in its docblock.
