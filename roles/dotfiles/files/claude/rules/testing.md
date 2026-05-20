# Testing Conventions

## Test File Organization

### Describe Block Ordering

The order of `describe` blocks in test files MUST match the order of functions/methods in the source file being tested.

**Rationale:**
- Easier navigation between source and test files
- Maintains consistency and predictability
- Simplifies code reviews
- Makes it easier to identify missing test coverage

**Example:**

Source file (`utils/calculator.ts`):
```typescript
export function add(a: number, b: number): number { ... }
export function subtract(a: number, b: number): number { ... }
export function multiply(a: number, b: number): number { ... }

✅ GOOD - Test file matches source order:
describe('add', () => { ... });
describe('subtract', () => { ... });
describe('multiply', () => { ... });

❌ BAD - Different order from source:
describe('multiply', () => { ... });
describe('add', () => { ... });
describe('subtract', () => { ... });

Classes and Nested Describe Blocks

For classes, nested describe blocks for methods should also follow the method definition order.

// Source: class methods in order: constructor, create, get, update, delete
describe('UserService', () => {
  describe('constructor', () => { ... });
  describe('create', () => { ... });
  describe('get', () => { ... });
  describe('update', () => { ... });
  describe('delete', () => { ... });
});

Adding New Tests

When adding new describe blocks to existing test files:
- Insert the block at the position matching the source file order
- Do NOT simply append to the end of the file

Test Setup and Helpers

Test setup code (beforeEach, afterEach, helper functions) should be placed:
- At the top of the test file, before all describe blocks
- Or at the top of each describe block if scoped to that suite
