# Function Ordering Convention

## Core Principle: Depth-First Caller-Callee Ordering

Functions should be ordered so that private/helper functions immediately follow their caller.
This creates a "step-down" reading experience where high-level logic appears first, followed by its implementation details.

## Ordering Rules

1. **Public/exported functions first**
  - Entry points and API surface at the top
  - Public functions should be sorted by a functional group
2. **Private helpers immediately after their caller**
  - Depth-first traversal
3. **Call order preserved**
  - If A calls B then C, B's subtree comes before C
  - Public functions are not subject to this restriction

## Examples

### Basic Example

```go
// ✅ GOOD - Depth-first ordering
func ProcessOrder(order Order) error {  // Public entry point
    if err := validateOrder(order); err != nil {
        return err
    }
    return saveOrder(order)
}

func validateOrder(order Order) error {  // Called by ProcessOrder
    return checkInventory(order.Items)   // Calls checkInventory
}

func checkInventory(items []Item) error { // Called by validateOrder
    // implementation
}

func saveOrder(order Order) error {       // Called by ProcessOrder (after validate)
    // implementation
}

// ❌ BAD - Alphabetical or random ordering
func checkInventory(items []Item) error { ... }
func ProcessOrder(order Order) error { ... }
func saveOrder(order Order) error { ... }
func validateOrder(order Order) error { ... }
```

### Deep Nesting Example
```typescript
// Call hierarchy: handleRequest → parseBody → decodeJSON → validateSchema
//                                           → sanitizeInput

// ✅ GOOD
export function handleRequest(req: Request) { ... }
function parseBody(body: string) { ... }
function decodeJSON(raw: string) { ... }
function validateSchema(data: unknown) { ... }  // Called by decodeJSON
function sanitizeInput(body: string) { ... }    // Called by parseBody (after decode)
```

### Edge Cases

**Multiple Callers**

When a function is called by multiple callers:

- 2 callers: Place after the first caller in depth-first order
- 3+ callers: Consider it a shared utility; place in a "Utilities" section at the end of the file, or extract to a separate module

```go
// ✅ Shared utility with 3+ callers → utilities section at end
func CreateUser() { ... uses formatName ... }
func UpdateUser() { ... uses formatName ... }
func ImportUsers() { ... uses formatName ... }

// --- Utilities ---
func formatName(name string) string { ... }
```

**Class Methods**

```typescript
For classes, apply the same principle within the class:

class OrderService {
  // Public methods first
  public async createOrder(data: OrderData): Promise<Order> {
    const validated = this.validateData(data);
    return this.persistOrder(validated);
  }

  // Private helpers follow their caller
  private validateData(data: OrderData): ValidatedData { ... }
  private persistOrder(data: ValidatedData): Promise<Order> { ... }

  // Another public method
  public async cancelOrder(id: string): Promise<void> {
    await this.checkCancellable(id);
    await this.refundPayment(id);
  }

  private checkCancellable(id: string): Promise<void> { ... }
  private refundPayment(id: string): Promise<void> { ... }
}
```

## Exceptions

1. Language conventions take precedence
  - Go: init() always near the top after package-level vars
  - Python: __init__, __enter__, __exit__ etc. follow class conventions
2. Interface implementations
  - Group interface methods together even if called from different places
3. Lifecycle methods
  - Constructor, destructor, lifecycle hooks should follow framework conventions

## Rationale

This ordering pattern (also known as "step-down rule" or "newspaper code"):
- Improves readability by showing high-level logic first
- Keeps related code physically close
- Makes it easier to understand call relationships
- Reduces scrolling when understanding a function and its helpers
