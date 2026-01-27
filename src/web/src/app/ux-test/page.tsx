"use client";

import { Button } from "@/components/ui/button";
import { motion } from "framer-motion";
import { Sparkles, Rocket, Zap } from "lucide-react";

export default function UXTestPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800 p-8">
      <div className="max-w-4xl mx-auto space-y-12">
        {/* Header con animazione */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="text-center space-y-4"
        >
          <motion.h1
            className="text-5xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent"
            initial={{ scale: 0.9 }}
            animate={{ scale: 1 }}
            transition={{ duration: 0.5, delay: 0.2 }}
          >
            🎨 UX Stack Test Page
          </motion.h1>
          <p className="text-xl text-slate-600 dark:text-slate-300">
            Testing WITUP UX Constitution Components
          </p>
        </motion.div>

        {/* Shadcn Button Test Section */}
        <motion.section
          initial={{ opacity: 0, x: -50 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.5, delay: 0.3 }}
          className="bg-white dark:bg-slate-800 rounded-2xl shadow-xl p-8 space-y-6"
        >
          <h2 className="text-2xl font-semibold text-slate-800 dark:text-white flex items-center gap-2">
            <Sparkles className="w-6 h-6 text-blue-500" />
            Shadcn/UI Components
          </h2>
          <div className="flex flex-wrap gap-4">
            <Button>Default Button</Button>
            <Button variant="destructive">Destructive</Button>
            <Button variant="outline">Outline</Button>
            <Button variant="secondary">Secondary</Button>
            <Button variant="ghost">Ghost</Button>
            <Button variant="link">Link</Button>
          </div>
          <div className="flex flex-wrap gap-4">
            <Button size="sm">Small</Button>
            <Button size="default">Default</Button>
            <Button size="lg">Large</Button>
            <Button size="icon">
              <Rocket className="w-5 h-5" />
            </Button>
          </div>
        </motion.section>

        {/* Framer Motion Animation Test */}
        <motion.section
          initial={{ opacity: 0, x: 50 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.5, delay: 0.5 }}
          className="bg-white dark:bg-slate-800 rounded-2xl shadow-xl p-8 space-y-6"
        >
          <h2 className="text-2xl font-semibold text-slate-800 dark:text-white flex items-center gap-2">
            <Zap className="w-6 h-6 text-yellow-500" />
            Framer Motion Animations
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <motion.div
              whileHover={{ scale: 1.05, rotate: 2 }}
              whileTap={{ scale: 0.95 }}
              className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl p-6 text-white cursor-pointer shadow-lg"
            >
              <h3 className="font-bold text-lg mb-2">Hover Me!</h3>
              <p className="text-sm opacity-90">Scale + Rotate animation</p>
            </motion.div>

            <motion.div
              animate={{ y: [0, -10, 0] }}
              transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
              className="bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl p-6 text-white shadow-lg"
            >
              <h3 className="font-bold text-lg mb-2">Floating</h3>
              <p className="text-sm opacity-90">Continuous Y animation</p>
            </motion.div>

            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 3, repeat: Infinity, ease: "linear" }}
              className="bg-gradient-to-br from-pink-500 to-pink-600 rounded-xl p-6 text-white shadow-lg flex items-center justify-center"
            >
              <Rocket className="w-12 h-12" />
            </motion.div>
          </div>
        </motion.section>

        {/* Lucide Icons Test */}
        <motion.section
          initial={{ opacity: 0, y: 50 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.7 }}
          className="bg-white dark:bg-slate-800 rounded-2xl shadow-xl p-8 space-y-6"
        >
          <h2 className="text-2xl font-semibold text-slate-800 dark:text-white flex items-center gap-2">
            <Rocket className="w-6 h-6 text-green-500" />
            Lucide React Icons
          </h2>
          <div className="flex flex-wrap gap-6 items-center">
            <motion.div whileHover={{ scale: 1.2, rotate: 15 }}>
              <Sparkles className="w-8 h-8 text-yellow-500" />
            </motion.div>
            <motion.div whileHover={{ scale: 1.2, rotate: -15 }}>
              <Rocket className="w-8 h-8 text-blue-500" />
            </motion.div>
            <motion.div whileHover={{ scale: 1.2, rotate: 180 }}>
              <Zap className="w-8 h-8 text-purple-500" />
            </motion.div>
          </div>
        </motion.section>

        {/* Status Report */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.5, delay: 0.9 }}
          className="bg-green-50 dark:bg-green-900/20 border-2 border-green-500 rounded-2xl p-6"
        >
          <h3 className="text-lg font-bold text-green-800 dark:text-green-200 mb-4">
            ✅ UX Stack Status
          </h3>
          <ul className="space-y-2 text-green-700 dark:text-green-300">
            <li>✓ Next.js 14+ (App Router) - Active</li>
            <li>✓ Shadcn/UI (Radix primitives) - Configured</li>
            <li>✓ TailwindCSS v4 - Running</li>
            <li>✓ Framer Motion - Animations Working</li>
            <li>✓ Lucide React - Icons Loaded</li>
            <li>✓ TypeScript - Type Safety Enabled</li>
          </ul>
        </motion.div>
      </div>
    </div>
  );
}
