// import { useState } from 'react'
import { Routes, Route, Navigate } from "react-router-dom"
import { useLocation } from "react-router-dom"
import { Analytics } from '@vercel/analytics/react'
import { SpeedInsights } from '@vercel/speed-insights/react'
import { NavBar }  from './Components/navbar'
import Landing from './pages/landing'
import Explore from './pages/explore'
import Upload from './pages/upload'
import Dashboard from './pages/dashboard'
import Template from './pages/template'
import Signup from './pages/signup'
import { Footer } from './Components/footer'
import { PopUp } from './Components/popup'
import EditTemplate from "./pages/editTemplate"
import EditDashboard from "./pages/editDashboard"
import Onboarding from "./pages/onboarding"
import './global.css'


function App() {
  const location = useLocation();

  const hideNavbar = [
    "/auth",
    "/onboarding",
  ].includes(location.pathname);

  return (
    <>
     {!hideNavbar && <NavBar />}
    <div className="flex min-h-dvh flex-col">
      <main className="flex-1">
        <Routes>
          <Route path="/" element={<Landing />} />
          <Route path="/explore" element={<Explore />} />
          <Route path="/upload" element={<Upload />} />
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/template/:id" element={<Template />} />
          <Route path="/template/:id/edit" element={<EditTemplate />} />
          <Route path="/auth" element={<Signup />} />
          <Route path="/onboarding" element={<Onboarding />} />
          <Route path="/dashboard/edit" element={<EditDashboard />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
      {!hideNavbar && <PopUp />}
      {!hideNavbar && <Footer /> }
      </div>
      <Analytics />
      <SpeedInsights />
    </>
  )
}

export default App
