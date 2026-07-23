# PikMe Testing Guide

## Setup

Install testing dependencies:
```bash
npm install --legacy-peer-deps
```

## Running Tests

### Run all tests
```bash
npm test
```

### Run tests in watch mode (auto-rerun on changes)
```bash
npm run test:watch
```

### Run tests with coverage report
```bash
npm run test:coverage
```

---

## Test Coverage

### ✅ Areas Covered

| Area | Tests | Status |
|---|---|---|
| **Scoring Engine** | `src/engine/recommendation.test.ts` | ✅ Core logic tested |
| **Hours Utility** | `src/utils/hours.test.ts` | ✅ Time calculations tested |
| **API Functions** | `src/api/functions.test.ts` | ✅ RPC calls mocked |
| **Components** | `src/components/menu/MenuItemCard.test.tsx` | ✅ Rendering tested |

### 📋 What's Tested

**Recommendation Engine:**
- ✅ Scoring algorithm
- ✅ Hard filters (dietary restrictions, allergens, calorie caps)
- ✅ Soft scoring (weighted rankings)
- ✅ Goal multipliers (weight loss, high protein, etc.)
- ✅ Top 20 results limiting

**Hours Utility:**
- ✅ Hour extraction from weekday_text
- ✅ Time delta calculation (opens/closes in X hours)
- ✅ Open/closed status
- ✅ Edge cases (missing data, empty arrays)

**API Functions:**
- ✅ User profile fetch/upsert
- ✅ Saved items retrieval
- ✅ Error handling
- ✅ Empty/null data handling

**Components:**
- ✅ MenuItemCard rendering
- ✅ Score display
- ✅ Nutrition info display
- ✅ Warnings and reasons
- ✅ Verified/estimated badge

---

## Writing New Tests

### Template

```typescript
describe('Feature Name', () => {
  const mockData = { /* ... */ };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should do something', () => {
    const result = myFunction(mockData);
    expect(result).toEqual(expectedValue);
  });

  it('should handle errors', async () => {
    await expect(myFunction(badData)).rejects.toThrow();
  });
});
```

### Key Testing Tips

1. **Mock external dependencies** (Supabase, location, router)
2. **Test both happy and error paths**
3. **Use descriptive test names** ("should filter vegan items for vegan users")
4. **Test edge cases** (empty arrays, null values, etc.)

---

## Coverage Thresholds

Minimum coverage requirements:
- **Branches:** 50%
- **Functions:** 50%
- **Lines:** 50%
- **Statements:** 50%

Check coverage:
```bash
npm run test:coverage
```

---

## Common Issues

### Tests timing out
- Increase timeout: `jest.setTimeout(10000)`
- Check for unresolved promises

### Mocks not working
- Clear mocks: `jest.clearAllMocks()`
- Check jest.mock() path is correct

### React Native imports failing
- Ensure jest.setup.js mocks all Expo modules
- Add new mocks as needed

---

## Continuous Testing (CI/CD)

Currently: **Local only** (`npm test` before push)

To add GitHub Actions (future):
```bash
# Create .github/workflows/test.yml
```

---

## Next Steps (Phase 7)

- [ ] Add integration tests (end-to-end flows)
- [ ] Test edge functions (Deno unit tests)
- [ ] Add E2E tests (Detox or Playwright)
- [ ] Set up GitHub Actions for automated testing
- [ ] Achieve 80%+ code coverage

---

**Last Updated:** June 16, 2026
