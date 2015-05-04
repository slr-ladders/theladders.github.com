---
author: Jose Medina
layout: post
title: "Working in Harmony: ES6 in a nutshell"
date: 2015-05-04 16:05
comments: true
categories: JavaScript
published: false
---

{% blockquote --Douglas Crockford, JavaScript: The Good Parts %}
"JavaScript is a language with more than its share of bad parts."
{% endblockquote %}

# Harmony
JavaScript, also known as ECMAScript, has extended its life beyond the boundaries of the browser. It can be found in [server side code](https://nodejs.org/), in [video game engines](http://docs.unity3d.com/Manual/CreatingAndUsingScripts.html), even frameworks to run C programs in the [browser](http://asmjs.org/). Unfortunately, the language specification has not been updated since 2009, which in turn has led to different frameworks and tools to accommodate for the lack of features.  Luckily, TC-39, the committee for approving ECMAScript, has a targeted release date of June 2015 for the next version of ECMAScript (ES6). ECMAScript is a significant update to the language and brings a slew of new features.

Here are several of the important features that will make the ES6 release:


#Modules
Modules provide private and public encapsulation to limit the creation of variables and functions on the global scope. They are part of a popular design pattern that has resulted in several frameworks such as [RequireJS](http://requirejs.org/), [Browserify](http://browserify.org/), and [Webpack](http://webpack.github.io/). ES6 provides a native solution that combines attributes of both CommonJS and AMD.

- Similar to CommonJS, native modules provide a compact syntax, a preference for single exports and support for cyclic dependencies.
- Similar to AMD, they have direct support for asynchronous loading and configurable module loading.

Let's look at an example of using native modules. Within a utility file, we have two functions, sumOfNumbers and logMessage. The module pattern allows us to choose which functions or attributes we want to expose to our consumers. There are two kinds of exports: 

- **named exports** (several per module), where the user specifies the name of the attribute on import. 
- **default exports** (one per module), where the compiler picks the export item labeled with the default keyword when it cannot match a named export. 

*Note:* You can run the following examples in babel's [live script editor](https://babeljs.io/repl/).  
```javascript
// lib/utility.js
export function sumOfNumbers(){
 var numbers = Array.prototype.slice.call(arguments);
 return numbers.reduce(function(x,y){ return x + y });
}

export default function logMessage(msg){
  console.log('Message is ', msg);
};

// app.js
import {logMessage, sumOfNumbers} from 'utility';

logMessage(sumOfNumbers(1,2,3,4,5)); // Message is 15
logMessage(sumOfNumbers(4,5,10)); // Message is 19
```

#Classes
ES6 brings classes to the language. The class implementation still uses prototypical inheritance, so it is syntactic sugar to make it easier to implement and understand.  Using the **extends** keyword provides the following benefits:

- Binds the correct context when using the *extends* keyword.
- Methods defined within the class block are defined on the prototype object.
- Provides the *super* keyword to easily invoke parent methods.

As a simple example of class inheritance, let's create a shape class with a triangle child class extending from shape.
```javascript
//Traditional way to create inheritance
function Shape(width, height){
  this.width = width;
  this.height = height;
}
Shape.prototype.printObject = function(){
  console.log('Shape', this.width, this.height);
};

function Triangle(width, height){
//Note: not a convenient way to invoke parent constructor
// we have to call the parent object with Triangle's context.
  Shape.call(this, width, height);
  this.sides = 3;
}
Triangle.prototype = Object.create(Shape.prototype); //prototype object now inheritances the properties of Shape

Triangle.prototype.printObject = function(){
  console.log('Triangle', this.width, this.height, this.sides);
};
```

```javascript
//ES6 Way to create inheritance
class Shape{
  width = 0; // properties of the class
  height = 0; // note: they are NOT private

  //function called with you call Shape with 'new' keyword
  constructor(width, height){
    this.width = width;
    this.height = height;
  }

  //method part of shape
  printObject(){
    console.log('Shape', this.width, this.height);
  }
}

class Triangle extends Shape{
  sides = 3;

  constructor(width, height){
    //invokes the parent constructor by calling super
    // automatically applies the correct context.
    super(width, height);
  }

  //Overrides the method on the parent object
  printObject(){
    //Draw the triangle
    console.log('Triangle', this.width, this.height);
  }
}
```
We can apply this new syntax to existing frameworks such as Backbone.

```javascript
//current backbone implementation
var MyView = Backbone.View.extend({
  template: '<div>Sample Template</div>',
  events: {
    'click' : 'clickHandler'
  },
  render: function(){
    this.$el.html(this.template);
    return this;
  },
  clickHandler: function(){
    alert('My view was clicked');
  }
});

//Backbone using classes
class MyView extends Backbone.View {
  constructor(options){
    this.template = '<div>Sample Template</div>';
    this.events = {
      'click' : 'clickHandler'
    };
    super(options);
  }
  render(){
    this.$el.html(this.template);
    return this;
  }
  clickHandler(){
    alert('My view was clicked');
  }
}
```

#Arrow Functions
ES6 has also added arrow functions, which provide a for more concise syntax for anonymous functions. However, there are a number of differences between arrow functions and traditional JavaScript functions:

- **Lexical *this* binding** - The value of *this* inside of the function is determined by where the arrow function is defined, not where it is used.
- **Not *new*-able** - Arrow functions do not have a constructor method and therefore can not be used to create instances. Arrow functions throw an error when called with "new".
- **Cannot change the value of *this*** - The value of *this* remains the same value throughout the lifecycle of the function.
- **No *arguments* object** - Function arguments are not accessible through the arguments object; you must use named arguments or ES6 [rest arguments](http://wiki.ecmascript.org/doku.php?id=harmony:rest_parameters).

Here is a simple example using arrow functions.  We are iterating of a list of items and printing out each number to the console.
```javascript
  var numbers = [4,5,6,7,9,10];
  //Current javascript implementation
  numbers.forEach(function(number){
    console.log(number);
  };

  // ES6 - Arrow functions
  numbers.forEach(number => {
    console.log(number);
  });
```
Let's look at more practical example using an event handler:
```javascript
//Current Javascript implementation
function Person(){
  this.$el = $('button');
  this.text = "Hello I am a person";
  
  //Problem with current Javascript that we have to "bind" the person context 
  // in order to get the callback to work properly.  Without "bind", the function
  // would print out undefined.
  this.$el.on('click', function(){
    console.log(this.text);
  }.bind(this));
}

//ES6
function Person(){
  this.$el = $('button');
  this.text = "Hello I am a person";
  
  //No longer need to "bind" the function since it is set to where it is defined.
  this.$el.on('click', () => {
    console.log(this.text);
  });
}
```

Arrow functions also provide different types of optional syntax.  Here are several examples:
```javascript
 var numbers = [1,2,3,4,5];
 var temp = null;
 
 //arrow functions return last value, no need for return statement.
 temp = numbers.map(number => number + 2);
 //need empty parentheses if no parameters are passed
 temp = numbers.map(() => 5);
 //multiple parameters 
 temp = numbers.reduce((x,y) => x + y);
```
# Destructing Variables
Destructuring allows binding via pattern matching. ES6 supports matching for arrays and objects. It will try to match the variable directly and return undefined when no match is found.
```javascript
 var numbers = [1,2,3,4];
 var obj = { a: 4, b: 'Hello', c: false };

 //first = 1, third = 3
 var [first, , third] = numbers;
 var {a,c} = obj;
 console.log(a); //prints out 4
 console.log(c); //prints out false

 //assigning value of 'b' in object to variable 'anotherName'
 var {b: anotherName} = obj;
 console.log(anotherName); //prints out 'Hello'
```

#Default, Rest, Spread
ES6 provides the flexibility to set default values for function parameters. It lets you grab trailing values without using the arguments keyword. And it also allows you to turn an array into consecutive arguments for a function call. With these options, there is no longer a need to use the arguments variable.

#####Default Parameter
- Current values that are not set are given a value of undefined. ES6 provides new syntax to add default values for parameters.
```javascript  
  function add2(a, b = 2){
     return a + b;
  }
  add2(2,5); // returns 7
  add2(2); //return 4
```
#####Rest parameter
- Currently, in order to grab all argument values as an array, we need to explicitly convert the values using the arguments keyword.
```javascript
  // Current Javascript
    //need to convert arguments into an array object in order to use any useful method.
  function sum(){
    var numbers = Array.prototype.slice.call(arguments);
    return numbers.reduce(function(x, y){ return x + y; });
  }

    // ES6
    // The conversion happens automatically. 
    function sum(...numbers){
      return numbers.reduce((x,y) => x + y);
    }
```
#####Spread parameter
- Spread functionality allows us to convert an array into consecutive arguments to pass into a function. Currently, we have to use the *apply* keyword in order to provide the same functionality.
```javascript
  //current implementation
  var numbers = [1,2,3,4,5];
  Math.max.apply(Math, numbers); //spreads the array and returns 5

  //Future implementation
  var numbers = [1,2,3,4,5];
  Math.max(...numbers); //performs the same action
```

# Current Alternatives
The JavaScript specification is targeted to release in June, but it could take browsers months to [implement](http://kangax.github.io/compat-table/es6/) these new features and years before users decide it's a good time to upgrade their browsers. Luckily, there are solutions which allow us to take advantage of these features right now. Here are several options:

###[<img src="https://raw.githubusercontent.com/babel/logo/master/logo.png" alt="Babel" width="250px">](https://babeljs.io/)

- A compiler for converting ES6 syntax to ES5-compatible javascript. Babel is among the most mature compilers for ES6 conversion with the options of extensible plugins as well as framework and tool integration. 

###[<img src="https://google.github.com/traceur-compiler/logo/tc.svg" alt="Traceur logo" width="200px"> Traceur](https://github.com/google/traceur-compiler)

- Google's version of Babel. Traceur is a JavaScript.next-to-JavaScript-of-today compiler that allows you to use features from the future today. Traceur supports ES6 as well as some experimental ES.next features.

###[<img src="http://www.typescriptlang.org/content/images/logo_small.png" alt="Typescript">](http://www.typescriptlang.org/)

- Typescript is a typed superset of JavaScript that compiles to plain JavaScript. It also provides the option of applying types to variables and functions at compile time. TypeScript provides the flexibility of using ES6 features such as classes, modules and arrow function which ultimately compile to ES5 compatible JavaScript. Similar to Babel, Typescript has integrations with many development environments and definition files for existing frameworks.

###[<img src="http://flowtype.org/static/flow-hero-logo.png" alt="Flow" width="200px">](http://flowtype.org/)

- Flow is a new static type checker for JavaScript. Flow is similar to Typescript in that it will compile down to plain JavaScript. The difference is that it provides valid checking for null variable type. Flow integrates well with other Facebook tools such as React and Flux.

#Conclusion
ECMAScript 6 provides an array of exciting tools and libraries that we can leverage to make development both easier and more exciting. Though we know that it could be months before we can use these tools natively, we have alternatives that allow developers to expand their toolsets and think of efficient and abstract solutions. If interested in learning more, here are several links:

####Resources: 
- [All ES6 Features](https://github.com/lukehoban/es6features)
- [Understanding ES6 - Nicolas Zakas](https://leanpub.com/understandinges6/)
- [Try ES6 Compilation using Babel](https://babeljs.io/docs/learn-es6/)
- [Evolution of Javascript - Netflix Javascript Talks](https://www.youtube.com/watch?v=DqMFX91ToLw)
- [EcmaScript 6 Draft](https://people.mozilla.org/~jorendorff/es6-draft.html)
