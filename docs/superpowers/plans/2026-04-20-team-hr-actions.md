# Team HR Actions — Full Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring `lib/team/` fully in line with `docs/modules/team_hr_actions_user_journeys.md` — confirmation dialogs, warning banners, action-specific UX details, color-coded history, inactive employee filter, and improved card/detail status display.

**Architecture:** All changes are pure frontend Flutter — no new files needed. Four existing files are modified: `add_hr_action_sheet.dart` (forms/validation/UX), `employee_detail_page.dart` (history display/discipline alerts), `employees_page.dart` (inactive toggle), `employee_card.dart` (status badges). No new services, models, or routes.

**Tech Stack:** Flutter/Dart, Material 3, `intl` (already imported), existing `TeamService` + `HrAction` + `Employee` models.

---

## Gap Analysis (current vs spec)

| Spec Requirement | Current State | Fix |
|---|---|---|
| Terminate: confirmation dialog + red banner | Just saves directly | Task 1 |
| Suspension: orange warning banner | None | Task 1 |
| Final Warning: orange warning banner | None | Task 1 |
| Performance review: 1–5 rating selector | Freetext notes only | Task 2 |
| Certificate: type dropdown | Freetext field | Task 2 |
| Bonus: description required + amount required | Only amount validated | Task 2 |
| Leave approval: auto day-count display | None | Task 2 |
| Suspension: validate return > start | None | Task 2 |
| Action-specific snackbar messages | Always "Saved" | Task 3 |
| History badges: color-coded by type | Plain grey icon | Task 4 |
| History: show old→new metadata (salary, position) | Not shown | Task 4 |
| Discipline alert: 2+ warnings → escalation card | None | Task 4 |
| Suspended/PIP status on detail page header | None | Task 4 |
| Employee card: inactive styling + status badge | No inactive differentiation | Task 5 |
| Employees list: "Show Inactive" toggle | Always shows active only | Task 5 |

---

## File Map

| File | Changes |
|---|---|
| `lib/team/widgets/add_hr_action_sheet.dart` | Tasks 1, 2, 3 |
| `lib/team/pages/employee_detail_page.dart` | Task 4 |
| `lib/team/widgets/employee_card.dart` | Task 5 |
| `lib/team/pages/employees_page.dart` | Task 5 |

---

## Task 1: Warning Banners + Terminate Confirmation Dialog

**Files:**
- Modify: `lib/team/widgets/add_hr_action_sheet.dart`

The `_AddHrActionSheetState._save()` method currently saves terminate immediately. The `build()` method renders no warning banners for destructive actions.

### Changes

- [ ] **Step 1: Add `_warningBanner()` helper** — insert after `_contractDropdown()` at line ~335, before `_actionFields()`:

```dart
Widget _warningBanner(String message, Color color) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Icon(Icons.warning_amber_rounded, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: TextStyle(fontSize: 12, color: color)),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 2: Add banner to `_actionFields()` for terminate, suspension, final_warning**

In the `switch (type)` inside `_actionFields()`:

For `case 'terminate':` — prepend the banner before the date field:
```dart
case 'terminate':
  return [
    _warningBanner(
      sw
          ? 'Hatua hii itafunga akaunti ya mfanyakazi. Hakikisha umechukua hatua sahihi za kisheria.'
          : 'This will deactivate the employee. Ensure proper legal offboarding steps are followed.',
      Colors.red,
    ),
    gap,
    _dateField(sw ? 'Tarehe ya Kumaliza' : 'Termination Date', _actionDate,
        () => _pickDate(false, sw)),
    gap,
    _descField(sw, required: true),
  ];
```

For `case 'final_warning':` — prepend orange banner:
```dart
case 'final_warning':
  return [
    _warningBanner(
      sw
          ? 'Onyo la Mwisho ni hatua kubwa ya kisheria. Hakikisha umefuata mchakato sahihi wa HR.'
          : 'Final Warning is a serious legal step. Ensure proper HR procedure has been followed.',
      Colors.orange,
    ),
    gap,
    _dateField(sw ? 'Tarehe ya Onyo' : 'Warning Date', _actionDate,
        () => _pickDate(false, sw)),
    gap,
    _descField(sw, required: true),
  ];
```

For `case 'suspension':` — prepend orange banner:
```dart
case 'suspension':
  return [
    _warningBanner(
      sw
          ? 'Kusimamishwa kutaweka is_active = false hadi tarehe ya kurudi.'
          : 'Suspension will deactivate the employee until the return date.',
      Colors.orange,
    ),
    gap,
    _dateField(sw ? 'Tarehe ya Kusimamishwa' : 'Suspension Date',
        _actionDate, () => _pickDate(false, sw)),
    gap,
    _dateField(sw ? 'Tarehe ya Kurudi' : 'Return Date', _effectiveDate,
        () => _pickDate(true, sw)),
    gap,
    _descField(sw, required: true),
  ];
```

- [ ] **Step 3: Add terminate confirmation dialog in `_save()`**

In `_save()`, after the `if (_selected == null)` guard and the action-specific validation block, insert before `setState(() => _saving = true)`:

```dart
// Confirmation dialog for destructive actions
if (type == 'terminate') {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        sw ? 'Thibitisha Kumaliza Mkataba' : 'Confirm Termination',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: Text(
        sw
            ? 'Una uhakika wa kumaliza mkataba wa mfanyakazi huyu? Hatua hii itaweka akaunti kuwa si hai.'
            : 'Are you sure you want to terminate this employee? This will set their account to inactive.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(sw ? 'Ghairi' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(sw ? 'Thibitisha' : 'Confirm'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
}
```

- [ ] **Step 4: Run analyzer**
```bash
flutter analyze lib/team/widgets/add_hr_action_sheet.dart 2>&1 | tail -10
```
Expected: `No issues found!`

---

## Task 2: Rating Selector, Certificate Dropdown, Bonus Validation, Leave Days, Suspension Validation

**Files:**
- Modify: `lib/team/widgets/add_hr_action_sheet.dart`

- [ ] **Step 1: Add `_rating` state variable and `_ratingWidget()` helper**

In `_AddHrActionSheetState`, add field after `String _contractType = 'permanent';`:
```dart
int _rating = 0; // 1-5 for performance_review
```

Add helper method after `_contractDropdown()`:
```dart
Widget _ratingSelector(bool sw) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        sw ? 'Tathmini (1–5)' : 'Rating (1–5)',
        style: const TextStyle(fontSize: 13, color: _kSecondary),
      ),
      const SizedBox(height: 8),
      Row(
        children: List.generate(5, (i) {
          final star = i + 1;
          return GestureDetector(
            onTap: () => setState(() => _rating = star),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                _rating >= star ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 32,
                color: _rating >= star ? Colors.amber : Colors.grey.shade300,
              ),
            ),
          );
        }),
      ),
      if (_rating > 0) ...[
        const SizedBox(height: 4),
        Text(
          [
            '',
            sw ? 'Mbaya (1)' : 'Poor (1)',
            sw ? 'Inabidi Kuboresha (2)' : 'Needs Improvement (2)',
            sw ? 'Wastani (3)' : 'Average (3)',
            sw ? 'Nzuri (4)' : 'Good (4)',
            sw ? 'Bora Sana (5)' : 'Excellent (5)',
          ][_rating],
          style: const TextStyle(fontSize: 12, color: _kSecondary),
        ),
      ],
    ],
  );
}
```

- [ ] **Step 2: Add `_certTypeDropdown()` helper**

Add after `_ratingSelector()`:
```dart
String _certType = 'service';

Widget _certTypeDropdown(bool sw) {
  final options = {
    'service':    sw ? 'Cheti cha Huduma'      : 'Certificate of Service',
    'appreciation': sw ? 'Barua ya Shukrani'   : 'Letter of Appreciation',
    'training':   sw ? 'Kukamilisha Mafunzo'   : 'Training Completion',
    'award':      sw ? 'Tuzo'                  : 'Award',
    'other':      sw ? 'Nyingine'              : 'Other',
  };
  return DropdownButtonFormField<String>(
    value: _certType,
    decoration: InputDecoration(
      labelText: sw ? 'Aina ya Cheti' : 'Certificate Type',
      prefixIcon: const Icon(Icons.workspace_premium_rounded,
          size: 20, color: _kSecondary),
      filled: true,
      fillColor: _kBackground,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    items: options.entries
        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
        .toList(),
    onChanged: (v) => setState(() => _certType = v ?? 'service'),
  );
}
```

Note: add `String _certType = 'service';` as a state field alongside `_rating`.

- [ ] **Step 3: Update `_actionFields()` for performance_review and certificate**

Replace `case 'performance_review':` with:
```dart
case 'performance_review':
  return [
    _dateField(sw ? 'Tarehe ya Tathmini' : 'Review Date', _actionDate,
        () => _pickDate(false, sw)),
    gap,
    _ratingSelector(sw),
    gap,
    _descField(sw),
  ];
```

Replace `case 'certificate':` with:
```dart
case 'certificate':
  return [
    _dateField(sw ? 'Tarehe' : 'Date', _actionDate,
        () => _pickDate(false, sw)),
    gap,
    _certTypeDropdown(sw),
    gap,
    _descField(sw),
  ];
```

- [ ] **Step 4: Leave approval — add auto-calculated days display**

Replace `case 'leave_approval':` with:
```dart
case 'leave_approval':
  final days = (_effectiveDate != null)
      ? _effectiveDate!.difference(_actionDate).inDays + 1
      : null;
  return [
    _dateField(sw ? 'Tarehe ya Kuanza Likizo' : 'Leave Start', _actionDate,
        () => _pickDate(false, sw)),
    gap,
    _dateField(sw ? 'Tarehe ya Kumaliza Likizo' : 'Leave End',
        _effectiveDate, () => _pickDate(true, sw)),
    if (days != null && days > 0) ...[
      gap,
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          sw ? 'Siku za likizo: $days' : 'Leave duration: $days days',
          style: TextStyle(
              fontSize: 13,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600),
        ),
      ),
    ],
    gap,
    _descField(sw),
  ];
```

- [ ] **Step 5: Update `_save()` validation — bonus description required, suspension date order, rating required, leave end ≥ start**

In `_save()`, inside the action-specific validation block (after existing position/dept/salary checks), add:

```dart
if (type == 'bonus') {
  final amt = double.tryParse(_bonusAmtCtrl.text.replaceAll(',', '')) ?? 0;
  if (amt <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sw ? 'Weka kiasi cha bonasi' : 'Enter bonus amount')));
    return;
  }
  if (_descCtrl.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sw ? 'Weka maelezo ya bonasi' : 'Enter bonus description')));
    return;
  }
}
if (type == 'suspension' && _effectiveDate != null) {
  if (!_effectiveDate!.isAfter(_actionDate)) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sw
            ? 'Tarehe ya kurudi lazima iwe baada ya tarehe ya kusimamishwa'
            : 'Return date must be after suspension date')));
    return;
  }
}
if (type == 'pip' && _effectiveDate != null) {
  final diff = _effectiveDate!.difference(_actionDate).inDays;
  if (diff < 30) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sw
            ? 'Mpango wa Kuboresha lazima uwe wa siku 30 au zaidi'
            : 'Improvement Plan must be at least 30 days')));
    return;
  }
}
if (type == 'leave_approval' && _effectiveDate != null) {
  if (_effectiveDate!.isBefore(_actionDate)) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sw
            ? 'Tarehe ya mwisho lazima iwe baada ya tarehe ya kuanza'
            : 'Leave end must be after leave start')));
    return;
  }
}
if (type == 'performance_review' && _rating == 0) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(sw ? 'Chagua tathmini (nyota)' : 'Select a rating')));
  return;
}
```

- [ ] **Step 6: Store rating and certType in metadata**

In the metadata-building block in `_save()`, add cases:
```dart
} else if (type == 'performance_review') {
  meta['rating'] = _rating;
} else if (type == 'certificate') {
  meta['certificate_type'] = _certType;
}
```

(Insert these after the existing `else if (type == 'contract_renewal')` block.)

- [ ] **Step 7: Run analyzer**
```bash
flutter analyze lib/team/widgets/add_hr_action_sheet.dart 2>&1 | tail -10
```
Expected: `No issues found!`

---

## Task 3: Action-Specific Snackbar Messages

**Files:**
- Modify: `lib/team/widgets/add_hr_action_sheet.dart`

The success snackbar in `_save()` currently always shows "Imehifadhiwa" / "Saved". Replace with action-specific messages.

- [ ] **Step 1: Add `_successMessage()` helper**

Add as a method in `_AddHrActionSheetState` before `_save()`:

```dart
String _successMessage(String type, bool sw) {
  switch (type) {
    case 'promote':          return sw ? 'Ukuzi wa cheo umehifadhiwa' : 'Promotion recorded';
    case 'transfer':         return sw ? 'Uhamishaji umehifadhiwa' : 'Transfer recorded';
    case 'terminate':        return sw ? 'Mkataba umemalizika' : 'Employment terminated';
    case 'rehire':           return sw ? 'Mfanyakazi ameajiriwa tena' : 'Employee rehired';
    case 'salary_review':    return sw ? 'Mshahara umesasishwa' : 'Salary updated';
    case 'bonus':            return sw ? 'Bonasi imehifadhiwa' : 'Bonus recorded';
    case 'warning':          return sw ? 'Onyo limehifadhiwa' : 'Warning recorded';
    case 'final_warning':    return sw ? 'Onyo la mwisho limehifadhiwa' : 'Final warning recorded';
    case 'suspension':       return sw ? 'Kusimamishwa kumehifadhiwa' : 'Suspension recorded';
    case 'leave_approval':   return sw ? 'Likizo imeidhinishwa' : 'Leave approved';
    case 'leave_rejection':  return sw ? 'Likizo imekataliwa' : 'Leave rejected';
    case 'performance_review': return sw ? 'Tathmini imehifadhiwa' : 'Review recorded';
    case 'pip':              return sw ? 'Mpango wa Kuboresha umewekwa' : 'Improvement plan created';
    case 'certificate':      return sw ? 'Cheti kimehifadhiwa' : 'Certificate recorded';
    case 'contract_renewal': return sw ? 'Mkataba umefanywa upya' : 'Contract renewed';
    default:                 return sw ? 'Imehifadhiwa' : 'Saved';
  }
}
```

- [ ] **Step 2: Use `_successMessage()` in `_save()`**

In `_save()`, replace:
```dart
messenger.showSnackBar(SnackBar(
    content: Text(sw ? 'Imehifadhiwa' : 'Saved')));
```
With:
```dart
messenger.showSnackBar(SnackBar(
    content: Text(_successMessage(type, sw))));
```

- [ ] **Step 3: Run analyzer**
```bash
flutter analyze lib/team/widgets/add_hr_action_sheet.dart 2>&1 | tail -10
```
Expected: `No issues found!`

---

## Task 4: Color-Coded History + Discipline Alert + Status Cards on Detail Page

**Files:**
- Modify: `lib/team/pages/employee_detail_page.dart`

### Changes needed
1. `_historyTile()` — colored badge, metadata old→new display
2. Discipline escalation card (if ≥2 warnings/final_warnings)
3. Status card when employee is suspended or has active PIP
4. `_historyBadgeColor()` helper

- [ ] **Step 1: Add `_badgeColor()` and `_badgeLabel()` helpers**

Add inside `_EmployeeDetailPageState` after `_categoryIcon()`:

```dart
Color _badgeColor(String actionType) {
  switch (actionType) {
    case 'promote':
    case 'rehire':           return Colors.green;
    case 'transfer':         return Colors.blue;
    case 'salary_review':
    case 'contract_renewal': return const Color(0xFF1565C0);
    case 'bonus':
    case 'certificate':      return const Color(0xFFF57F17); // gold
    case 'terminate':
    case 'warning':
    case 'final_warning':
    case 'leave_rejection':  return Colors.red;
    case 'suspension':
    case 'pip':              return Colors.orange;
    case 'leave_approval':   return Colors.teal;
    case 'performance_review': return Colors.indigo;
    default:                 return Colors.grey;
  }
}

String _metaDetail(HrAction a, bool sw) {
  final m = a.metadata;
  if (m == null) return '';
  switch (a.actionType) {
    case 'promote':
    case 'rehire':
      final oldPos = m['old_position']?.toString() ?? '';
      final newPos = m['new_position']?.toString() ?? '';
      final oldSal = m['old_salary'];
      final newSal = m['new_salary'];
      final parts = <String>[];
      if (oldPos.isNotEmpty && newPos.isNotEmpty && oldPos != newPos) {
        parts.add('$oldPos → $newPos');
      }
      if (oldSal != null && newSal != null) {
        final fmt = NumberFormat('#,###', 'en');
        final oldAmt = (oldSal is num) ? oldSal.toDouble() : double.tryParse(oldSal.toString()) ?? 0;
        final newAmt = (newSal is num) ? newSal.toDouble() : double.tryParse(newSal.toString()) ?? 0;
        if (oldAmt != newAmt) {
          parts.add('TZS ${fmt.format(oldAmt.round())} → TZS ${fmt.format(newAmt.round())}');
        }
      }
      return parts.join(' • ');
    case 'transfer':
      final oldDept = m['old_department']?.toString() ?? '';
      final newDept = m['new_department']?.toString() ?? '';
      if (oldDept.isNotEmpty && newDept.isNotEmpty) return '$oldDept → $newDept';
      return newDept;
    case 'salary_review':
      final oldSal = m['old_salary'];
      final newSal = m['new_salary'];
      if (oldSal != null && newSal != null) {
        final fmt = NumberFormat('#,###', 'en');
        final oldAmt = (oldSal is num) ? oldSal.toDouble() : double.tryParse(oldSal.toString()) ?? 0;
        final newAmt = (newSal is num) ? newSal.toDouble() : double.tryParse(newSal.toString()) ?? 0;
        return 'TZS ${fmt.format(oldAmt.round())} → TZS ${fmt.format(newAmt.round())}';
      }
      return '';
    case 'bonus':
      final amt = m['bonus_amount'];
      if (amt != null) {
        final fmt = NumberFormat('#,###', 'en');
        final d = (amt is num) ? amt.toDouble() : double.tryParse(amt.toString()) ?? 0;
        return 'TZS ${fmt.format(d.round())}';
      }
      return '';
    case 'performance_review':
      final r = m['rating'];
      if (r != null) return '★ $r / 5';
      return '';
    case 'certificate':
      return m['certificate_type']?.toString() ?? '';
    case 'contract_renewal':
      final ct = m['contract_type']?.toString() ?? '';
      switch (ct) {
        case 'permanent': return sw ? 'Kudumu' : 'Permanent';
        case 'contract':  return sw ? 'Mkataba' : 'Contract';
        case 'part_time': return sw ? 'Sehemu ya Wakati' : 'Part-time';
        default: return ct;
      }
    default:
      return '';
  }
}
```

- [ ] **Step 2: Replace `_historyTile()` with updated version**

Replace the entire `_historyTile()` method:

```dart
Widget _historyTile(HrAction a, bool sw) {
  final dateStr = DateFormat('dd MMM yyyy').format(a.actionDate);
  final color = _badgeColor(a.actionType);
  final meta = _metaDetail(a, sw);

  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(_categoryIcon(a.category), size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(_historyLabel(a.actionType, sw),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(dateStr,
                        style: TextStyle(fontSize: 10, color: color)),
                  ),
                ],
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(meta,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
              if (a.description != null && a.description!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(a.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ],
            ],
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(Icons.close_rounded, size: 15, color: Colors.red),
          onPressed: () => _confirmDeleteAction(a, sw),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 3: Add discipline escalation card and status banner helpers**

Add these two helpers inside `_EmployeeDetailPageState` before `build()`:

```dart
// Returns a warning card if employee has 2+ discipline actions
Widget? _disciplineAlertCard(bool sw) {
  final disciplineCount = _hrActions
      .where((a) => a.actionType == 'warning' || a.actionType == 'final_warning')
      .length;
  if (disciplineCount < 2) return null;
  final hasFinal = _hrActions.any((a) => a.actionType == 'final_warning');
  final msg = hasFinal
      ? (sw
          ? 'Mfanyakazi huyu ana Onyo la Mwisho. Fikiria hatua zaidi kama ni lazima.'
          : 'This employee has a Final Warning on record. Consider next steps if issues continue.')
      : (sw
          ? 'Mfanyakazi huyu ana maonyo $disciplineCount. Kama tatizo linaendelea, toa Onyo la Mwisho.'
          : 'This employee has $disciplineCount warnings. If issues persist, consider a Final Warning.');
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.orange.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(msg,
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
        ),
      ],
    ),
  );
}

// Returns a status banner for suspended or PIP-active employees
Widget? _statusBanner(Employee emp, bool sw) {
  if (!emp.isActive) {
    // Check if suspended (vs terminated)
    final suspension = _hrActions
        .where((a) => a.actionType == 'suspension')
        .toList()
      ..sort((a, b) => b.actionDate.compareTo(a.actionDate));
    if (suspension.isNotEmpty && suspension.first.effectiveDate != null) {
      final returnDate = suspension.first.effectiveDate!;
      final returnStr = DateFormat('dd MMM yyyy').format(returnDate);
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.block_rounded, color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                sw
                    ? 'Amesimamishwa — Anarudi: $returnStr'
                    : 'Suspended — Return date: $returnStr',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
  }
  // Check for active PIP
  final pips = _hrActions
      .where((a) => a.actionType == 'pip')
      .toList()
    ..sort((a, b) => b.actionDate.compareTo(a.actionDate));
  if (pips.isNotEmpty && pips.first.effectiveDate != null) {
    final endDate = pips.first.effectiveDate!;
    if (endDate.isAfter(DateTime.now())) {
      final daysLeft = endDate.difference(DateTime.now()).inDays;
      final endStr = DateFormat('dd MMM yyyy').format(endDate);
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.deepOrange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.deepOrange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Colors.deepOrange.shade700, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                sw
                    ? 'PIP Inaendelea — Inaisha: $endStr ($daysLeft siku zilizobaki)'
                    : 'Improvement Plan Active — Ends: $endStr ($daysLeft days remaining)',
                style: TextStyle(fontSize: 12, color: Colors.deepOrange.shade800,
                    fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
  }
  return null;
}
```

- [ ] **Step 4: Wire banners into `build()` — insert after avatar card**

In `build()`, inside the `ListView` children list, after the avatar card `const SizedBox(height: 12),` and before the details card, add:

```dart
// Status/discipline banners (shown between avatar and details cards)
if (_statusBanner(emp, sw) != null) _statusBanner(emp, sw)!,
if (_disciplineAlertCard(sw) != null) _disciplineAlertCard(sw)!,
```

- [ ] **Step 5: Add `DateFormat` import if missing**

Ensure `import 'package:intl/intl.dart';` is already at line 3 of the file (it is — already imported). `DateFormat` is part of `intl`.

- [ ] **Step 6: Run analyzer**
```bash
flutter analyze lib/team/pages/employee_detail_page.dart 2>&1 | tail -10
```
Expected: `No issues found!`

---

## Task 5: Show Inactive Toggle (EmployeesPage) + Status Badge (EmployeeCard)

**Files:**
- Modify: `lib/team/pages/employees_page.dart`
- Modify: `lib/team/widgets/employee_card.dart`

### EmployeeCard — Status Badge

- [ ] **Step 1: Update `EmployeeCard` to show inactive/status badge**

In `employee_card.dart`, inside the `build()` method, the card's `Row` currently ends with the salary column + popup menu. Add an inactive visual treatment.

Replace the card `decoration` to show a faded style when inactive:
```dart
color: employee.isActive ? _kCardBg : Colors.grey.shade50,
border: Border.all(
  color: employee.isActive ? Colors.grey.shade100 : Colors.grey.shade200,
),
```

After the `Expanded` name/position column, before the salary `Column`, insert a status chip when inactive:
```dart
if (!employee.isActive) ...[
  Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      sw ? 'Hayupo' : 'Inactive',
      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
    ),
  ),
],
```

Also apply opacity to the avatar and text when inactive:
- Wrap `CircleAvatar` in `Opacity(opacity: employee.isActive ? 1.0 : 0.5, child: ...)`.

- [ ] **Step 2: Verify no new constructor params needed**

`EmployeeCard` already receives `Employee employee` which has `isActive`. No interface change needed.

### EmployeesPage — Show Inactive Toggle

- [ ] **Step 3: Add `_showInactive` state and toggle to `EmployeesPage`**

In `_EmployeesPageState`, add field:
```dart
bool _showInactive = false;
```

In `_filteredForBusiness()`, replace:
```dart
List<Employee> _filteredForBusiness(int businessId) {
  final all = _employeesByBusiness[businessId] ?? [];
  final q = _searchCtrl.text.trim().toLowerCase();
  final filtered = _showInactive ? all : all.where((e) => e.isActive).toList();
  if (q.isEmpty) return filtered;
  return filtered
      .where((e) =>
          e.name.toLowerCase().contains(q) ||
          (e.position ?? '').toLowerCase().contains(q))
      .toList();
}
```

- [ ] **Step 4: Add toggle row to the `build()` search bar area**

In `build()`, inside the `Padding` that wraps the search `TextField`, add a toggle row after the `TextField`:

```dart
Padding(
  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
  child: Column(
    children: [
      TextField(/* existing search field */),
      const SizedBox(height: 8),
      Row(
        children: [
          Icon(Icons.visibility_outlined, size: 16, color: _kSecondary),
          const SizedBox(width: 6),
          Text(
            sw ? 'Onyesha wasio hai' : 'Show inactive',
            style: const TextStyle(fontSize: 13, color: _kSecondary),
          ),
          const Spacer(),
          Switch.adaptive(
            value: _showInactive,
            onChanged: (v) => setState(() => _showInactive = v),
            activeColor: _kPrimary,
          ),
        ],
      ),
    ],
  ),
),
```

Note: the existing `Padding` wraps only the `TextField`. Expand it to wrap a `Column` containing both the `TextField` and the toggle row.

- [ ] **Step 5: Run analyzer on both files**
```bash
flutter analyze lib/team/widgets/employee_card.dart lib/team/pages/employees_page.dart 2>&1 | tail -10
```
Expected: `No issues found!`

---

## Task 6: Final Verification

- [ ] **Step 1: Run full team module analysis**
```bash
flutter analyze lib/team/ 2>&1 | tail -15
```
Expected: `No issues found!`

- [ ] **Step 2: Self-audit checklist**

Walk through each gap in the gap analysis table at the top of this plan and confirm each row is addressed:

| Gap | Task | Done? |
|---|---|---|
| Terminate confirmation dialog | Task 1 | ☐ |
| Red banner for terminate | Task 1 | ☐ |
| Orange banner for suspension | Task 1 | ☐ |
| Orange banner for final_warning | Task 1 | ☐ |
| Performance review rating (1–5 stars) | Task 2 | ☐ |
| Certificate type dropdown | Task 2 | ☐ |
| Bonus: description required | Task 2 | ☐ |
| Leave approval: day count display | Task 2 | ☐ |
| Suspension date order validation | Task 2 | ☐ |
| PIP 30-day minimum validation | Task 2 | ☐ |
| Rating required validation | Task 2 | ☐ |
| Action-specific snackbar messages | Task 3 | ☐ |
| Color-coded history badges | Task 4 | ☐ |
| History: old→new metadata display | Task 4 | ☐ |
| Discipline escalation card | Task 4 | ☐ |
| Suspended/PIP status banner | Task 4 | ☐ |
| Inactive employee card styling | Task 5 | ☐ |
| Show Inactive toggle | Task 5 | ☐ |

---

## Out of Scope (backend or infra required)

These items from the user journey spec require backend or FCM infrastructure and are **not implemented** in this plan:

- Push notifications (require FCM token registration + backend trigger endpoints)
- Local scheduled notifications (require `flutter_local_notifications` scheduling setup)
- Calendar cross-module sync (requires CalendarService.createEvent() backend endpoint)
- Budget cross-module sync (requires ExpenditureService call with correct envelope IDs)
- Shangazi AI "Ask" buttons (require Shangazi chat deep-link or context API)

These should be tracked as a separate plan once backend endpoints are confirmed.
