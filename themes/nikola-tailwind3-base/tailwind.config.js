const heading = ['"Open Sans"', 'Roboto', 'Arial', 'sans-serif'];

module.exports = {
    content: [
        './themes/**/*.tmpl',
        './posts/**/*.{md,html}',
        './pages/**/*.{md,rst,html}',
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
