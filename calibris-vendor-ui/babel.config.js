module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      // Makes the "@/..." imports used throughout src/ actually resolve at
      // bundle time. tsconfig.json's "paths" only helps the TypeScript
      // checker/editor — Metro needs this separate config to do the same
      // thing at runtime, otherwise every "@/..." import fails to resolve
      // and the app renders a blank screen with no visible error.
      [
        'module-resolver',
        {
          root: ['./'],
          alias: {
            '@': './src',
          },
          extensions: ['.ios.js', '.android.js', '.js', '.jsx', '.tsx', '.ts', '.json'],
        },
      ],
    ],
  };
};
