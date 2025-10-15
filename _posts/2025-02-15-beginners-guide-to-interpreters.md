---
layout: "post"
date: 2025-02-15
title: "A Beginner's Guide to Interpreters: From Operational Semantics to Implementation"
categories: "language-design"
draft: false
---

In our previous articles on operational semantics, we explored the formal foundations of programming language execution. We learned how to precisely define what programs mean through mathematical rules that describe step-by-step evaluation. Now, it's time to bridge the gap between theory and practice by building an actual interpreter—a program that executes other programs.

This guide will take you from the operational semantics we've already studied to a working interpreter implementation. We'll build a complete interpreter for a small functional programming language, demonstrating how formal semantics translate into executable code.

## What Is an Interpreter?

An interpreter is a program that directly executes source code without first translating it to machine code. Unlike a compiler, which translates source code to another language (typically machine code), an interpreter reads and executes programs on-the-fly.

Think of the difference this way:
- A **compiler** translates a book from English to French, then you read the French version
- An **interpreter** reads the English book aloud to you, translating as it goes

Interpreters are everywhere in modern computing: Python, JavaScript, Ruby, and many other languages rely on interpreters for execution. Even compiled languages often use interpreters for their REPLs (Read-Eval-Print Loops) and just-in-time compilation.

## The Interpreter Pipeline

Most interpreters follow a standard pipeline of phases:

1. **Lexical Analysis (Tokenization)**: Breaking source code into tokens (keywords, identifiers, operators, etc.)
2. **Parsing**: Building an Abstract Syntax Tree (AST) from the tokens
3. **Evaluation**: Executing the AST according to the language's semantics

This pipeline mirrors the operational semantics we studied: parsing creates the expressions, and evaluation follows the semantic rules we defined.

## Our Target Language

We'll build an interpreter for a simple functional language that extends the arithmetic language from our operational semantics articles. Here's the syntax:

```
e ::= n                    (Numbers)
    | x                    (Variables)
    | e + e                (Addition)
    | e - e                (Subtraction)
    | e * e                (Multiplication)
    | e / e                (Division)
    | if e then e else e   (Conditionals)
    | λx.e                 (Functions)
    | e e                  (Function application)
    | let x = e in e       (Let bindings)
```

This is essentially the language we defined in our operational semantics articles, with the addition of `let` expressions for convenience.

## Phase 1: Lexical Analysis

The first step is breaking source code into tokens. A token is the smallest meaningful unit of a program—like a word in a sentence.

Let's implement a simple lexer in Python:

```python
import re
from enum import Enum
from typing import List, Tuple, Optional

class TokenType(Enum):
    NUMBER = "NUMBER"
    IDENTIFIER = "IDENTIFIER"
    LAMBDA = "LAMBDA"
    LET = "LET"
    IN = "IN"
    IF = "IF"
    THEN = "THEN"
    ELSE = "ELSE"
    PLUS = "PLUS"
    MINUS = "MINUS"
    MULTIPLY = "MULTIPLY"
    DIVIDE = "DIVIDE"
    EQUALS = "EQUALS"
    LPAREN = "LPAREN"
    RPAREN = "RPAREN"
    DOT = "DOT"
    EOF = "EOF"

class Token:
    def __init__(self, type: TokenType, value: str, position: int):
        self.type = type
        self.value = value
        self.position = position
    
    def __repr__(self):
        return f"Token({self.type.value}, '{self.value}', {self.position})"

class Lexer:
    def __init__(self, text: str):
        self.text = text
        self.position = 0
        self.tokens = []
    
    def tokenize(self) -> List[Token]:
        """Convert input text into a list of tokens."""
        while self.position < len(self.text):
            self._skip_whitespace()
            if self.position >= len(self.text):
                break
            
            token = self._next_token()
            if token:
                self.tokens.append(token)
        
        self.tokens.append(Token(TokenType.EOF, "", self.position))
        return self.tokens
    
    def _skip_whitespace(self):
        """Skip whitespace characters."""
        while self.position < len(self.text) and self.text[self.position].isspace():
            self.position += 1
    
    def _next_token(self) -> Optional[Token]:
        """Extract the next token from the input."""
        current_pos = self.position
        char = self.text[self.position]
        
        # Numbers
        if char.isdigit():
            return self._read_number()
        
        # Identifiers and keywords
        if char.isalpha() or char == '_':
            return self._read_identifier()
        
        # Single character tokens
        token_map = {
            '+': TokenType.PLUS,
            '-': TokenType.MINUS,
            '*': TokenType.MULTIPLY,
            '/': TokenType.DIVIDE,
            '=': TokenType.EQUALS,
            '(': TokenType.LPAREN,
            ')': TokenType.RPAREN,
            '.': TokenType.DOT
        }
        
        if char in token_map:
            self.position += 1
            return Token(token_map[char], char, current_pos)
        
        raise SyntaxError(f"Unexpected character '{char}' at position {current_pos}")
    
    def _read_number(self) -> Token:
        """Read a number token."""
        start_pos = self.position
        while (self.position < len(self.text) and 
               self.text[self.position].isdigit()):
            self.position += 1
        
        value = self.text[start_pos:self.position]
        return Token(TokenType.NUMBER, value, start_pos)
    
    def _read_identifier(self) -> Token:
        """Read an identifier or keyword token."""
        start_pos = self.position
        while (self.position < len(self.text) and 
               (self.text[self.position].isalnum() or 
                self.text[self.position] == '_')):
            self.position += 1
        
        value = self.text[start_pos:self.position]
        
        # Check if it's a keyword
        keyword_map = {
            'let': TokenType.LET,
            'in': TokenType.IN,
            'if': TokenType.IF,
            'then': TokenType.THEN,
            'else': TokenType.ELSE,
            'lambda': TokenType.LAMBDA
        }
        
        token_type = keyword_map.get(value, TokenType.IDENTIFIER)
        return Token(token_type, value, start_pos)
```

Let's test our lexer with a simple example:

```python
# Test the lexer
text = "let x = 5 in x + 3"
lexer = Lexer(text)
tokens = lexer.tokenize()

for token in tokens:
    print(token)
```

This would output:
```
Token(LET, 'let', 0)
Token(IDENTIFIER, 'x', 4)
Token(EQUALS, '=', 6)
Token(NUMBER, '5', 8)
Token(IN, 'in', 10)
Token(IDENTIFIER, 'x', 13)
Token(PLUS, '+', 15)
Token(NUMBER, '3', 17)
Token(EOF, '', 19)
```

## Phase 2: Parsing

Now we need to convert our tokens into an Abstract Syntax Tree (AST). The AST represents the syntactic structure of our program in a tree format that's easy to evaluate.

Let's define our AST nodes:

```python
from abc import ABC, abstractmethod
from typing import Any, Optional

class ASTNode(ABC):
    """Base class for all AST nodes."""
    pass

class Number(ASTNode):
    def __init__(self, value: int):
        self.value = value
    
    def __repr__(self):
        return f"Number({self.value})"

class Variable(ASTNode):
    def __init__(self, name: str):
        self.name = name
    
    def __repr__(self):
        return f"Variable('{self.name}')"

class BinaryOp(ASTNode):
    def __init__(self, left: ASTNode, operator: str, right: ASTNode):
        self.left = left
        self.operator = operator
        self.right = right
    
    def __repr__(self):
        return f"BinaryOp({self.left}, '{self.operator}', {self.right})"

class Conditional(ASTNode):
    def __init__(self, condition: ASTNode, then_expr: ASTNode, else_expr: ASTNode):
        self.condition = condition
        self.then_expr = then_expr
        self.else_expr = else_expr
    
    def __repr__(self):
        return f"Conditional({self.condition}, {self.then_expr}, {self.else_expr})"

class Lambda(ASTNode):
    def __init__(self, parameter: str, body: ASTNode):
        self.parameter = parameter
        self.body = body
    
    def __repr__(self):
        return f"Lambda('{self.parameter}', {self.body})"

class Application(ASTNode):
    def __init__(self, function: ASTNode, argument: ASTNode):
        self.function = function
        self.argument = argument
    
    def __repr__(self):
        return f"Application({self.function}, {self.argument})"

class Let(ASTNode):
    def __init__(self, variable: str, value: ASTNode, body: ASTNode):
        self.variable = variable
        self.value = value
        self.body = body
    
    def __repr__(self):
        return f"Let('{self.variable}', {self.value}, {self.body})"
```

Now let's implement a recursive descent parser:

```python
class Parser:
    def __init__(self, tokens: List[Token]):
        self.tokens = tokens
        self.position = 0
    
    def parse(self) -> ASTNode:
        """Parse tokens into an AST."""
        expr = self.parse_expression()
        if self.current_token().type != TokenType.EOF:
            raise SyntaxError("Unexpected token after expression")
        return expr
    
    def current_token(self) -> Token:
        """Get the current token."""
        if self.position >= len(self.tokens):
            return Token(TokenType.EOF, "", 0)
        return self.tokens[self.position]
    
    def advance(self):
        """Move to the next token."""
        if self.position < len(self.tokens):
            self.position += 1
    
    def expect(self, expected_type: TokenType):
        """Expect a specific token type and advance."""
        token = self.current_token()
        if token.type != expected_type:
            raise SyntaxError(f"Expected {expected_type.value}, got {token.type.value}")
        self.advance()
        return token
    
    def parse_expression(self) -> ASTNode:
        """Parse an expression (lowest precedence)."""
        return self.parse_let()
    
    def parse_let(self) -> ASTNode:
        """Parse let expressions."""
        if self.current_token().type == TokenType.LET:
            self.advance()  # consume 'let'
            var_token = self.expect(TokenType.IDENTIFIER)
            self.expect(TokenType.EQUALS)
            value = self.parse_expression()
            self.expect(TokenType.IN)
            body = self.parse_expression()
            return Let(var_token.value, value, body)
        return self.parse_conditional()
    
    def parse_conditional(self) -> ASTNode:
        """Parse conditional expressions."""
        if self.current_token().type == TokenType.IF:
            self.advance()  # consume 'if'
            condition = self.parse_expression()
            self.expect(TokenType.THEN)
            then_expr = self.parse_expression()
            self.expect(TokenType.ELSE)
            else_expr = self.parse_expression()
            return Conditional(condition, then_expr, else_expr)
        return self.parse_application()
    
    def parse_application(self) -> ASTNode:
        """Parse function applications (left-associative)."""
        left = self.parse_primary()
        
        while (self.current_token().type in [TokenType.IDENTIFIER, TokenType.LPAREN] or
               self.current_token().type == TokenType.NUMBER):
            right = self.parse_primary()
            left = Application(left, right)
        
        return left
    
    def parse_primary(self) -> ASTNode:
        """Parse primary expressions (numbers, variables, lambdas, parentheses)."""
        token = self.current_token()
        
        if token.type == TokenType.NUMBER:
            self.advance()
            return Number(int(token.value))
        
        elif token.type == TokenType.IDENTIFIER:
            self.advance()
            return Variable(token.value)
        
        elif token.type == TokenType.LAMBDA:
            self.advance()
            param_token = self.expect(TokenType.IDENTIFIER)
            self.expect(TokenType.DOT)
            body = self.parse_expression()
            return Lambda(param_token.value, body)
        
        elif token.type == TokenType.LPAREN:
            self.advance()
            expr = self.parse_expression()
            self.expect(TokenType.RPAREN)
            return expr
        
        else:
            raise SyntaxError(f"Unexpected token: {token}")
    
    def parse_binary_expression(self, higher_precedence_parser, operators: List[TokenType]) -> ASTNode:
        """Parse binary expressions with given precedence."""
        left = higher_precedence_parser()
        
        while self.current_token().type in operators:
            op_token = self.current_token()
            self.advance()
            right = higher_precedence_parser()
            
            # Create binary operation node
            op_map = {
                TokenType.PLUS: '+',
                TokenType.MINUS: '-',
                TokenType.MULTIPLY: '*',
                TokenType.DIVIDE: '/'
            }
            left = BinaryOp(left, op_map[op_token.type], right)
        
        return left
```

We need to update our parser to handle arithmetic operations with proper precedence. Let me add the missing methods:

```python
# Add these methods to the Parser class
def parse_conditional(self) -> ASTNode:
    """Parse conditional expressions."""
    if self.current_token().type == TokenType.IF:
        self.advance()  # consume 'if'
        condition = self.parse_arithmetic()
        self.expect(TokenType.THEN)
        then_expr = self.parse_arithmetic()
        self.expect(TokenType.ELSE)
        else_expr = self.parse_arithmetic()
        return Conditional(condition, then_expr, else_expr)
    return self.parse_arithmetic()

def parse_arithmetic(self) -> ASTNode:
    """Parse arithmetic expressions with proper precedence."""
    return self.parse_binary_expression(
        self.parse_term,
        [TokenType.PLUS, TokenType.MINUS]
    )

def parse_term(self) -> ASTNode:
    """Parse multiplication and division."""
    return self.parse_binary_expression(
        self.parse_application,
        [TokenType.MULTIPLY, TokenType.DIVIDE]
    )
```

Let's test our parser:

```python
# Test the parser
text = "let x = 5 in x + 3 * 2"
lexer = Lexer(text)
tokens = lexer.tokenize()
parser = Parser(tokens)
ast = parser.parse()
print(ast)
```

This would output:
```
Let('x', Number(5), BinaryOp(Variable('x'), '+', BinaryOp(Number(3), '*', Number(2))))
```

## Phase 3: Evaluation

Now comes the exciting part—implementing the evaluator that executes our AST according to the operational semantics we defined earlier. This is where theory becomes practice.

```python
from typing import Dict, Any, Callable

class Environment:
    """Environment for storing variable bindings."""
    def __init__(self, parent: Optional['Environment'] = None):
        self.bindings: Dict[str, Any] = {}
        self.parent = parent
    
    def define(self, name: str, value: Any):
        """Define a variable in this environment."""
        self.bindings[name] = value
    
    def lookup(self, name: str) -> Any:
        """Look up a variable, searching parent environments if needed."""
        if name in self.bindings:
            return self.bindings[name]
        elif self.parent:
            return self.parent.lookup(name)
        else:
            raise NameError(f"Undefined variable: {name}")

class Function:
    """Represents a function value with its environment."""
    def __init__(self, parameter: str, body: ASTNode, env: Environment):
        self.parameter = parameter
        self.body = body
        self.env = env
    
    def __repr__(self):
        return f"Function('{self.parameter}', {self.body})"

class Interpreter:
    """The main interpreter class."""
    def __init__(self):
        self.global_env = Environment()
    
    def interpret(self, ast: ASTNode, env: Optional[Environment] = None) -> Any:
        """Interpret an AST node in the given environment."""
        if env is None:
            env = self.global_env
        
        if isinstance(ast, Number):
            return ast.value
        
        elif isinstance(ast, Variable):
            return env.lookup(ast.name)
        
        elif isinstance(ast, BinaryOp):
            left_val = self.interpret(ast.left, env)
            right_val = self.interpret(ast.right, env)
            return self._apply_binary_op(ast.operator, left_val, right_val)
        
        elif isinstance(ast, Conditional):
            condition_val = self.interpret(ast.condition, env)
            if condition_val != 0:  # Non-zero is truthy
                return self.interpret(ast.then_expr, env)
            else:
                return self.interpret(ast.else_expr, env)
        
        elif isinstance(ast, Lambda):
            return Function(ast.parameter, ast.body, env)
        
        elif isinstance(ast, Application):
            func_val = self.interpret(ast.function, env)
            arg_val = self.interpret(ast.argument, env)
            return self._apply_function(func_val, arg_val)
        
        elif isinstance(ast, Let):
            value_val = self.interpret(ast.value, env)
            new_env = Environment(env)
            new_env.define(ast.variable, value_val)
            return self.interpret(ast.body, new_env)
        
        else:
            raise RuntimeError(f"Unknown AST node type: {type(ast)}")
    
    def _apply_binary_op(self, operator: str, left: Any, right: Any) -> Any:
        """Apply a binary operator to two values."""
        if not isinstance(left, (int, float)) or not isinstance(right, (int, float)):
            raise TypeError(f"Cannot apply {operator} to non-numeric values")
        
        if operator == '+':
            return left + right
        elif operator == '-':
            return left - right
        elif operator == '*':
            return left * right
        elif operator == '/':
            if right == 0:
                raise ZeroDivisionError("Division by zero")
            return left / right
        else:
            raise RuntimeError(f"Unknown operator: {operator}")
    
    def _apply_function(self, func: Any, arg: Any) -> Any:
        """Apply a function to an argument."""
        if not isinstance(func, Function):
            raise TypeError(f"Cannot apply non-function value: {func}")
        
        # Create new environment with the parameter bound to the argument
        new_env = Environment(func.env)
        new_env.define(func.parameter, arg)
        
        # Evaluate the function body in the new environment
        return self.interpret(func.body, new_env)
    
    def evaluate(self, source: str) -> Any:
        """Evaluate source code directly."""
        lexer = Lexer(source)
        tokens = lexer.tokenize()
        parser = Parser(tokens)
        ast = parser.parse()
        return self.interpret(ast)
```

Let's test our complete interpreter:

```python
# Test the complete interpreter
interpreter = Interpreter()

# Test arithmetic
result1 = interpreter.evaluate("5 + 3 * 2")
print(f"5 + 3 * 2 = {result1}")  # Should print: 5 + 3 * 2 = 11

# Test variables
result2 = interpreter.evaluate("let x = 10 in x + 5")
print(f"let x = 10 in x + 5 = {result2}")  # Should print: let x = 10 in x + 5 = 15

# Test conditionals
result3 = interpreter.evaluate("if 5 then 10 else 20")
print(f"if 5 then 10 else 20 = {result3}")  # Should print: if 5 then 10 else 20 = 10

# Test functions
result4 = interpreter.evaluate("(lambda x. x + 1) 5")
print(f"(lambda x. x + 1) 5 = {result4}")  # Should print: (lambda x. x + 1) 5 = 6

# Test higher-order functions
result5 = interpreter.evaluate("let add = lambda x. lambda y. x + y in add 3 4")
print(f"let add = lambda x. lambda y. x + y in add 3 4 = {result5}")  # Should print: 7
```

## Connecting to Operational Semantics

Our interpreter implementation directly mirrors the operational semantics we defined in our previous articles. Let's trace through how `(lambda x. x + 1) 5` evaluates:

1. **Parsing**: Creates `Application(Lambda('x', BinaryOp(Variable('x'), '+', Number(1))), Number(5))`
2. **Evaluation**: 
   - Function evaluates to `Function('x', BinaryOp(Variable('x'), '+', Number(1)), env)`
   - Argument evaluates to `5`
   - New environment created with `x ↦ 5`
   - Function body `x + 1` evaluated in new environment
   - Variable `x` looked up, yielding `5`
   - Binary operation `5 + 1` performed, yielding `6`

This exactly matches our operational semantics rule for function application:
```
<(λx.e) v, ρ> → <e, ρ[x ↦ v]>
```

## Error Handling

Let's add proper error handling to make our interpreter more robust:

```python
class InterpreterError(Exception):
    """Base class for interpreter errors."""
    pass

class SyntaxError(InterpreterError):
    """Syntax error during parsing."""
    pass

class RuntimeError(InterpreterError):
    """Runtime error during evaluation."""
    pass

class NameError(InterpreterError):
    """Undefined variable error."""
    pass

class TypeError(InterpreterError):
    """Type error during evaluation."""
    pass

class ZeroDivisionError(InterpreterError):
    """Division by zero error."""
    pass

# Update the interpreter methods to use these custom exceptions
```

## Adding a REPL

Let's create a simple Read-Eval-Print Loop to make our interpreter interactive:

```python
def repl():
    """Start an interactive REPL."""
    interpreter = Interpreter()
    print("Welcome to our functional language interpreter!")
    print("Type 'quit' to exit.")
    
    while True:
        try:
            source = input("> ")
            if source.strip().lower() == 'quit':
                break
            
            if source.strip():
                result = interpreter.evaluate(source)
                print(f"= {result}")
        
        except KeyboardInterrupt:
            print("\nGoodbye!")
            break
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    repl()
```

## What We've Built

In this guide, we've created a complete interpreter for a functional programming language that includes:

- **Lexical analysis** for tokenizing source code
- **Parsing** for building Abstract Syntax Trees  
- **Evaluation** following operational semantics principles
- **Variables** with lexical scoping
- **Functions** with closures
- **Conditionals** for control flow
- **Let bindings** for local definitions
- **Error handling** for robust execution
- **Interactive REPL** for experimentation

This implementation demonstrates how the formal operational semantics we studied in our previous articles translate directly into working code. Each evaluation rule we defined mathematically now has a corresponding implementation in our interpreter.

## Next Steps

This interpreter provides a solid foundation for understanding how programming languages work. You could extend it with:

- **Recursion** support (using fixed-point combinators)
- **Data structures** (lists, tuples, records)
- **Pattern matching** for data decomposition
- **Modules** and imports for code organization
- **Garbage collection** for memory management
- **Optimizations** like tail call elimination
- **Type checking** and type inference

## Conclusion

We've successfully bridged the gap between the formal operational semantics we studied earlier and a working interpreter implementation. This demonstrates how theoretical foundations in programming language theory directly inform practical language implementation.

The interpreter we built follows the same evaluation rules we defined in our operational semantics articles, showing how formal specifications translate into executable code. This connection between theory and practice is crucial for understanding programming languages deeply and building reliable language implementations.

Through this journey from operational semantics to interpreter implementation, we've seen how:

1. **Formal semantics** provide precise specifications for language behavior
2. **Lexical analysis** breaks source code into manageable tokens
3. **Parsing** constructs meaningful syntax trees from token streams
4. **Evaluation** executes programs according to semantic rules
5. **Environments** manage variable bindings and lexical scoping
6. **Closures** capture function definitions with their environments

By understanding both the formal foundations and the implementation details, you're now equipped to explore more advanced topics in programming language design, compiler construction, and language implementation. The principles we've covered form the foundation for understanding how real-world languages like Python, JavaScript, and Haskell are implemented.