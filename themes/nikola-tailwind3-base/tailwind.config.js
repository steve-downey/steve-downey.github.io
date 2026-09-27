const heading = ['"Open Sans"', 'Roboto', 'Arial', 'sans-serif'];

module.exports = {
    // Scan only the templates for utility classes. Post/page bodies are org /
    // Markdown prose (styled via the typography plugin), not authored with
    // Tailwind utilities -- scanning them only fed org-mode export class names
    // into the generator. In particular org's section wrappers
    // .outline-2/.outline-3 collide with Tailwind's outline-<width> utilities,
    // which draw a stray outline box around every heading section.
    content: [
        './themes/**/*.tmpl',
    ],
    darkMode: 'class',
    plugins: [require('@tailwindcss/typography')],
    theme: {
        extend: {
            fontFamily: {
                sans: ['"Source Sans 3"'].concat(heading),
                heading: heading,
                mono: ['"Source Code Pro"', 'Inconsolata', 'ui-monospace',
                       'Courier', 'monospace'],
            },
            typography: {
                DEFAULT: {
                    css: {
                        'h1, h2, h3, h4, h5, h6': {
                            fontFamily: heading.join(', '),
                        },
                    },
                },
            },
        },
    },
};
